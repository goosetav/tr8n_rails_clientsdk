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
#-- Tr8nClientSdk::Component Schema Information
#
# Table name: tr8n_components
#
#  id                INTEGER         not null, primary key
#  application_id    integer         
#  key               varchar(255)    
#  state             varchar(255)    
#  name              varchar(255)    
#  description       varchar(255)    
#  created_at        datetime        not null
#  updated_at        datetime        not null
#
# Indexes
#
#  tr8n_comp_app_id    (application_id) 
#
#++

class Tr8nClientSdk::Component < ActiveRecord::Base
  self.table_name = :tr8n_components
  attr_accessible :application_id, :key, :name, :description, :state
  
  belongs_to :application, :class_name => 'Tr8nClientSdk::Application'

  has_many :component_sources, :class_name => 'Tr8nClientSdk::ComponentSource', :dependent => :destroy
  has_many :translation_sources, :class_name => 'Tr8nClientSdk::TranslationSource', :through => :component_sources
  has_many :translation_key_sources, :class_name => 'Tr8nClientSdk::TranslationKeySource', :through => :translation_sources
  has_many :translation_keys, :class_name => 'Tr8nClientSdk::TranslationKey', :through => :translation_key_sources

  has_many :component_languages, :class_name => 'Tr8nClientSdk::ComponentLanguage', :dependent => :destroy
  has_many :languages, :class_name => 'Tr8nClientSdk::Language', :through => :component_languages

  has_many :component_translators, :class_name => 'Tr8nClientSdk::ComponentTranslator', :dependent => :destroy
  has_many :translators, :class_name => 'Tr8nClientSdk::Translator', :through => :component_translators

  alias :sources :translation_sources

  def self.cache_key(key)
    "component_[#{key.to_s}]"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.find_or_create(key)
    return component if key.is_a?(Tr8nClientSdk::Component)
    key = key.to_s

    Tr8nClientSdk::Cache.fetch(cache_key(key)) do 
      where("key = ?", key.to_s).first || create(:key => key.to_s, :state => "restricted")
    end  
  end

  def live?
    state == "live"
  end

  def restricted?
    state == "restricted"
  end

  def translator_authorized?(translator = Tr8nClientSdk::Config.current_translator)
    return true unless restricted?
    translators.include?(translator)
  end

end
