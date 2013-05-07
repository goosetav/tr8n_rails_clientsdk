#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
#-- Tr8nClientSdk::TranslationSource Schema Information
#
# Table name: tr8n_translation_sources
#
#  id                       INTEGER         not null, primary key
#  parent_id                integer         
#  source                   varchar(255)    
#  translation_domain_id    integer         
#  completeness             integer         
#  name                     varchar(255)    
#  description              varchar(255)    
#  url                      varchar(255)    
#  key_count                integer         
#  created_at               datetime        not null
#  updated_at               datetime        not null
#
# Indexes
#
#  tr8n_ts_pid    (parent_id) 
#  tr8n_ts_s      (source) 
#
#++

class Tr8nClientSdk::TranslationSource < ActiveRecord::Base
  self.table_name = :tr8n_translation_sources
  attr_accessible :source, :translation_domain_id, :url, :name, :description, :translation_domain, :key_count

  after_destroy   :clear_cache
  after_save      :clear_cache
  
  belongs_to  :translation_domain,            :class_name => "Tr8nClientSdk::TranslationDomain"
  
  has_many    :translation_key_sources,       :class_name => "Tr8nClientSdk::TranslationKeySource",      :dependent => :destroy
  has_many    :translation_keys,              :class_name => "Tr8nClientSdk::TranslationKey",            :through => :translation_key_sources
  has_many    :translation_source_languages,  :class_name => "Tr8nClientSdk::TranslationSourceLanguage", :dependent => :destroy
  has_many    :translation_source_metrics,    :class_name => 'Tr8nClientSdk::TranslationSourceMetric',   :dependent => :destroy
  has_many    :component_sources,             :class_name => "Tr8nClientSdk::ComponentSource",           :dependent => :destroy
  has_many    :components,                    :class_name => "Tr8nClientSdk::Component",                 :through => :component_sources
  
  alias :domain   :translation_domain
  alias :sources  :translation_key_sources
  alias :keys     :translation_keys
  alias :metrics  :translation_source_metrics
  
  def self.normalize_api_source(url)
    uri = URI.parse(url)
    "#{uri.host}#{uri.path}"
  end

  def self.cache_key(source)
    "source_[#{source.to_s}]"
  end

  def cache_key
    self.class.cache_key(source)
  end

  def clear_cache
    Tr8nClientSdk::Cache.delete(cache_key)
  end
  
  def self.find_or_create(source, url = nil)
    return source if source.is_a?(Tr8nClientSdk::TranslationSource)
    source = source.to_s.split("://").last.split("?").first

    Tr8nClientSdk::Cache.fetch(cache_key(source)) do 
      source = where("source = ?", source).first || create(:source => source)
      source.update_attributes(
        :key_count => Tr8nClientSdk::TranslationKeySource.count(:id, :conditions => ["translation_source_id = ?", source.id])
      )
      source
    end  
  end

  def update_metrics!(language = Tr8nClientSdk::Config.current_language)
    metric = total_metric(language)
    Tr8nClientSdk::OfflineTask.schedule(metric.class.name, :update_metrics_offline, {
                               :translation_source_metric_id => metric.id, 
    })
  end

  def total_metric(language = Tr8nClientSdk::Config.current_language)
    Tr8nClientSdk::TranslationSourceMetric.find_or_create(self, language)
  end


  def cache_key_for_language(language = Tr8nClientSdk::Config.current_language)
    "translations_for_[#{self.source}]_#{language.locale}"
  end

  def cache(language = Tr8nClientSdk::Config.current_language)
    @cache ||= {}
    @cache[language.locale] ||= begin
      Tr8nClientSdk::Cache.fetch(cache_key_for_language(language)) do 
        hash = {}
        translation_keys.each do |tkey|
          hash[tkey.key] = {
            "translation_key" => tkey,
            "translations" => tkey.valid_translations_for_language(language)
          }
        end
        hash
      end
    end
  end

  def translation_key_for_key(key)
    (cache[key] || {})["translation_key"]
  end

  def valid_translations_for_key_and_language(key, language = Tr8nClientSdk::Config.current_language)
    (cache[key] || {})["translations"]
  end

  def clear_cache_for_language(language = Tr8nClientSdk::Config.current_language)
    Tr8nClientSdk::Cache.delete(cache_key_for_language(language))
  end

  def self.options
    @sources = Tr8nClientSdk::TranslationSource.find(:all, :order => "source asc").collect{|src| [src.source, src.source]}
  end

  def title
    return source if name.blank?
    name
  end

  def name_and_source
    return source if name.blank?
    "#{name} (#{source})"
  end

  def translator_authorized?(translator = Tr8nClientSdk::Config.current_translator)
    components.each do |comp|
      return false unless comp.translator_authorized?(translator)
    end
    true
  end
end
