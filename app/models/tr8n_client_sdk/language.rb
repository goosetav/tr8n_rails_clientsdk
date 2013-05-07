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
#-- Tr8nClientSdk::Language Schema Information
#
# Table name: tr8n_languages
#
#  id                      INTEGER         not null, primary key
#  locale                  varchar(255)    not null
#  english_name            varchar(255)    not null
#  native_name             varchar(255)    
#  threshold               integer         default = 1
#  enabled                 boolean         
#  right_to_left           boolean         
#  completeness            integer         
#  fallback_language_id    integer         
#  curse_words             text            
#  featured_index          integer         default = 0
#  google_key              varchar(255)    
#  facebook_key            varchar(255)    
#  myheritage_key          varchar(255)    
#  created_at              datetime        not null
#  updated_at              datetime        not null
#
# Indexes
#
#  tr8n_ll    (locale) 
#
#++

class Tr8nClientSdk::Language < ActiveRecord::Base
  self.table_name = :tr8n_languages  
  attr_accessible :locale, :english_name, :native_name, :enabled, :right_to_left, :completenss, :fallback_language_id, :curse_words, :featured_index
  attr_accessible :google_key, :facebook_key, :myheritage_key
  attr_accessible :fallback_language

  after_save      :update_cache
  after_destroy   :update_cache

  belongs_to :fallback_language,    :class_name => 'Tr8nClientSdk::Language', :foreign_key => :fallback_language_id
  
  has_many :language_rules,         :class_name => 'Tr8nClientSdk::LanguageRule',        :dependent => :destroy, :order => "type asc"
  has_many :language_cases,         :class_name => 'Tr8nClientSdk::LanguageCase',        :dependent => :destroy, :order => "id asc"
  has_many :language_users,         :class_name => 'Tr8nClientSdk::LanguageUser',        :dependent => :destroy
  has_many :translations,           :class_name => 'Tr8nClientSdk::Translation',         :dependent => :destroy
  has_many :translation_key_locks,  :class_name => 'Tr8nClientSdk::TranslationKeyLock',  :dependent => :destroy
  has_many :language_metrics,       :class_name => 'Tr8nClientSdk::LanguageMetric'
  
  ###############################################################
  ## CACHE METHODS
  ###############################################################
  def self.cache_key(locale)
    "language_[#{locale}]"
  end

  def cache_key
    self.class.cache_key(locale)
  end
  
  def context_rules_cache_key
    "rules_[#{locale}]"
  end

  def language_cases_cache_key
    "cases_[#{locale}]"
  end

  def self.featured_languages_cache_key
    "featured_languages"
  end

  def self.enabled_languages_cache_key
    "enabled_languages"
  end

  def update_cache
    Tr8nClientSdk::Cache.delete(cache_key)
    Tr8nClientSdk::Cache.delete(context_rules_cache_key)
    Tr8nClientSdk::Cache.delete(language_cases_cache_key)
    Tr8nClientSdk::Cache.delete(self.class.featured_languages_cache_key)
    Tr8nClientSdk::Cache.delete(self.class.enabled_languages_cache_key)
  end

  ###############################################################
  ## FINDER METHODS
  ###############################################################
  def self.for(locale)
    return nil if locale.nil?
    Tr8nClientSdk::Cache.fetch(cache_key(locale)) do 
      find_by_locale(locale)
    end
  end

  def self.find_or_create(lcl, english_name)
    find_by_locale(lcl) || create(:locale => lcl, :english_name => english_name) 
  end

  def rules
    Tr8nClientSdk::Cache.fetch(context_rules_cache_key) do 
      language_rules
    end
  end

  def cases
    Tr8nClientSdk::Cache.fetch(language_cases_cache_key) do 
      language_cases
    end
  end

  def reset!
    reset_language_rules!
    reset_language_cases!
  end
  
  # reloads rules for the language from the yml file
  def reset_language_rules!
    rules.delete_all
    Tr8nClientSdk::Config.language_rule_classes.each do |rule_class|
      rule_class.default_rules_for(self).each do |definition|
        rule_class.create(:language => self, :definition => definition)
      end
    end
  end
  
  # reloads language cases for the language from the yml file
  def reset_language_cases!
    cases.delete_all
    Tr8nClientSdk::Config.default_language_cases_for(locale).each do |lcase|
      rules = lcase.delete(:rules)
      language_case = Tr8nClientSdk::LanguageCase.create(lcase.merge(:language => self, :translator => Tr8nClientSdk::Config.system_translator))
      next if rules.blank?
      rules.keys.sort.each_with_index do |lrkey, index|
        lcrule = rules[lrkey]
        Tr8nClientSdk::LanguageCaseRule.create(:language_case => language_case, :language => self, :translator => Tr8nClientSdk::Config.system_translator, :position => index, :definition => lcrule)
      end
    end
  end
  
  def current?
    self.locale == Tr8nClientSdk::Config.current_language.locale
  end
  
  def default?
    self.locale == Tr8nClientSdk::Config.default_locale
  end
  
  def flag
    locale
  end
  
  # deprecated
  def has_rules?
    rules?
  end

  def rules?
    not rules.empty?
  end
  
  def gender_rules?
    return false unless rules?
    
    rules.each do |rule|
      return true if rule.class.dependency == 'gender'
    end
    false
  end

  def cases?
    not cases.empty?
  end

  def case_keyword_maps
    @case_keyword_maps ||= begin
      hash = {} 
      cases.each do |lcase| 
        hash[lcase.keyword] = lcase
      end
      hash
    end
  end
  
  def suggestible?
    not google_key.blank?
  end
  
  def case_for(case_keyword)
    case_keyword_maps[case_keyword]
  end
  
  def valid_case?(case_keyword)
    case_for(case_keyword) != nil
  end
  
  def full_name
    return english_name if english_name == native_name
    "#{english_name} - #{native_name}"
  end

  def self.options
    enabled_languages.collect{|lang| [lang.english_name, lang.id.to_s]}
  end
  
  def self.locale_options
    enabled_languages.collect{|lang| [lang.english_name, lang.locale]}
  end

  def self.filter_options
    find(:all, :order => "english_name asc").collect{|lang| [lang.english_name, lang.id.to_s]}
  end
  
  def enable!
    self.enabled = true
    save
  end

  def disable!
    self.enabled = false
    save
  end
  
  def disabled?
    not enabled?
  end
  
  def dir
    right_to_left? ? "rtl" : "ltr"
  end
  
  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end
  
  def self.enabled_languages
    Tr8nClientSdk::Cache.fetch(enabled_languages_cache_key) do 
      find(:all, :conditions => ["enabled = ?", true], :order => "english_name asc")
    end
  end

  def self.featured_languages
    Tr8nClientSdk::Cache.fetch(featured_languages_cache_key) do 
      find(:all, :conditions => ["enabled = ? and featured_index is not null and featured_index > 0", true], :order => "featured_index desc")
    end
  end

  def self.translate(label, desc = "", tokens = {}, options = {})
    Tr8nClientSdk::Config.current_language.translate(label, desc, tokens, options)
  end

  def translate(label, desc = "", tokens = {}, options = {})
    raise Tr8nClientSdk::Exception.new("The label #{label} is being translated twice") if label.tr8n_translated?

    unless Tr8nClientSdk::Config.enabled?
      return Tr8nClientSdk::TranslationKey.substitute_tokens(label, tokens, options, self).tr8n_translated.html_safe
    end

    translation_key = Tr8nClientSdk::TranslationKey.find_or_create(label, desc, options)
    translation_key.translate(self, tokens.merge(:viewing_user => Tr8nClientSdk::Config.current_user), options).tr8n_translated.html_safe
  end
  alias :tr :translate

  def trl(label, desc = "", tokens = {}, options = {})
    tr(label, desc, tokens, options.merge(:skip_decorations => true))
  end

  def default_rule
    @default_rule ||= Tr8nClientSdk::Config.language_rule_classes.first.new(:language => self, :definition => {})
  end
  
  def rule_classes  
    @rule_classes ||= rules.collect{|r| r.class}.uniq
  end

  def rule_class_names  
    @rule_class_names ||= rule_classes.collect{|r| r.name}
  end

  def dependencies  
    @dependencies ||= rule_classes.collect{|r| r.dependency}.uniq
  end

  def default_rules_for(dependency)
    rules.select{|r| r.class.dependency == dependency}
  end

  def has_gender_rules?
    dependencies.include?("gender")
  end
  
  def threshold
    super || Tr8nClientSdk::Config.translation_threshold
  end

end
