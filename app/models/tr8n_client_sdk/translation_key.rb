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

require 'digest/md5'
# require 'tr8n_client_sdk/api'

class Tr8nClientSdk::TranslationKey < ActiveRecord::Base
  self.table_name = :tr8n_translation_keys
  attr_accessible :key, :label, :description, :verified_at, :translation_count, :admin, :locale, :level, :synced_at
  
  # include Tr8nClientSdk::Api

  has_many :translations,             :class_name => "Tr8nClientSdk::Translation",           :dependent => :destroy
  has_many :translation_key_locks,    :class_name => "Tr8nClientSdk::TranslationKeyLock",    :dependent => :destroy
  has_many :translation_key_sources,  :class_name => "Tr8nClientSdk::TranslationKeySource",  :dependent => :destroy
  has_many :translation_sources,      :class_name => "Tr8nClientSdk::TranslationSource",     :through => :translation_key_sources
  has_many :translation_domains,      :class_name => "Tr8nClientSdk::TranslationDomain",     :through => :translation_sources
  has_many :translation_key_comments, :class_name => "Tr8nClientSdk::TranslationKeyComment", :dependent => :destroy, :order => "created_at desc"
  
  alias :locks        :translation_key_locks
  alias :key_sources  :translation_key_sources
  alias :sources      :translation_sources
  alias :domains      :translation_domains
  alias :comments     :translation_key_comments

  def self.cache_key(key_hash)
    "translation_key_[#{key_hash}]"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.find_or_create(label, desc = "", options = {})
    key = generate_key(label, desc).to_s

    # Rails.logger.debug("********* Fetching key from source: #{Tr8nClientSdk::Config.current_source.source}")

    tkey = Tr8nClientSdk::Config.current_source.translation_key_for_key(key)
    tkey ||= begin
      # pp "key for label #{label} not found in cache"
      existing_key = where(:key => key).first
      
      level = options[:level] || Tr8nClientSdk::Config.block_options[:level] || Tr8nClientSdk::Config.default_translation_key_level
      role_key = options[:role] || Tr8nClientSdk::Config.block_options[:role] 
      if role_key
        level = Tr8nClientSdk::Config.translator_roles[role_key]
        raise Tr8nClientSdk::Exception("Unknown translator role: #{role_key}") unless level 
      end

      locale = options[:locale] || Tr8nClientSdk::Config.block_options[:default_locale] || Tr8nClientSdk::Config.default_locale
      
      existing_key ||= create(:key => key.to_s, 
                              :label => label, 
                              :description => desc, 
                              :locale => locale,
                              :level => level,
                              :admin => Tr8nClientSdk::Config.block_options[:admin])
      
      track_source(existing_key, options)  
      existing_key
    end
  end

  # creates associations between the translation keys and sources
  # used for the site map and javascript support
  def self.track_source(translation_key, options = {})
    # source can be passed into an individual key, or as a block or fall back on the controller/action
    source = options[:source] || Tr8nClientSdk::Config.current_source_from_block_options || Tr8nClientSdk::Config.current_source
    translation_source = Tr8nClientSdk::TranslationSource.find_or_create(source)

    # each key is associated with one or more sources
    translation_key_source = Tr8nClientSdk::TranslationKeySource.find_or_create(translation_key, translation_source)
    Tr8nClientSdk::Config.current_source.clear_cache_for_language

    # for debugging purposes only - this will track the actual location of the key in the source
    if Tr8nClientSdk::Config.enable_key_caller_tracking?    
      options[:caller] ||= caller
      options[:caller_key] = options[:caller].is_a?(Array) ? options[:caller].join(", ") : options[:caller].to_s
      options[:caller_key] = generate_key(options[:caller_key])
      translation_key_source.update_details!(options)
    end
  end

  def self.generate_key(label, desc = "")
    "#{Digest::MD5.hexdigest("#{label};;;#{desc}")}~"[0..-2]
  end

  # for key merging
  def reset_key!
    Tr8nClientSdk::Cache.delete(cache_key)
    self.update_attributes(:key => self.class.generate_key(label, description))
  end
  
  def language
    @language ||= (locale ? Tr8nClientSdk::Language.for(locale) : Tr8nClientSdk::Config.default_language)
  end
  
  def tokenized_label
    @tokenized_label ||= Tr8nClientSdk::TokenizedLabel.new(label)
  end

  delegate :tokens, :tokens?, :to => :tokenized_label
  delegate :data_tokens, :data_tokens?, :to => :tokenized_label
  delegate :decoration_tokens, :decoration_tokens?, :to => :tokenized_label
  delegate :translation_tokens, :translation_tokens?, :to => :tokenized_label
  delegate :sanitized_label, :tokenless_label, :suggestion_tokens, :words, :to => :tokenized_label

  # returns only the tokens that depend on one or more rules of the language, if any defined for the language
  def language_rules_dependant_tokens(language = Tr8nClientSdk::Config.current_language)
    toks = []
    included_token_hash = {}

    data_tokens.each do |token|
      next unless token.dependant?
      next if included_token_hash[token.name]
      
      token.language_rules.each do |rule_class|
        if language.rule_class_names.include?(rule_class.name)
          toks << token
          included_token_hash[token.name] = token
        end
      end
    end

    toks << Tr8nClientSdk::Config.viewing_user_token_for(label) if language.gender_rules?
    toks.uniq
  end

  def lock_for(language)
    Tr8nClientSdk::TranslationKeyLock.for(self, language)
  end
  
  def locked?(language = Tr8nClientSdk::Config.current_language)
    lock_for(language).locked?
  end

  def unlocked?(language = Tr8nClientSdk::Config.current_language)
    not locked?(language)
  end

  # returns all translations for the key, language and minimal rank
  def translations_for(language = nil, rank = nil)
    translations = Tr8nClientSdk::Translation.where("translation_key_id = ?", self.id)
    if language
      translations = translations.where("language_id in (?)", [language].flatten.collect{|lang| lang.id})
    end
    translations = translations.where("rank >= ?", rank) if rank
    translations.order("rank desc").all
  end

  # used by the inline popup dialog, we don't want to show blocked translations
  def inline_translations_for(language)
    translations_for(language, -50)
  end

  def translations_cache_key(language)
    "translations_#{language.locale}_#{key}"
  end
  
  def clear_translations_cache_for_language(language = Tr8nClientSdk::Config.current_language)
    Tr8nClientSdk::Cache.delete(translations_cache_key(language)) 
  end  

  def valid_translations_for_language(language = Tr8nClientSdk::Config.current_language)
    translations_for(language, language.threshold)
  end

  # used by all translation methods
  def cached_translations_for_language(language = Tr8nClientSdk::Config.current_language)
    @cached_translations ||= begin 
      translations = Tr8nClientSdk::Config.current_source.valid_translations_for_key_and_language(self.key, language)
      # pp "found #{translations.count} cached translations for #{self.label}" if translations
      translations || valid_translations_for_language(language)
    end
  end
  
  def translation_with_such_rules_exist?(language_translations, translator, rules_hash)
    language_translations.each do |translation|
      return true if translation.matches_rule_definitions?(rules_hash)
    end
    false
  end
  
  ###########################################################################
  # returns back grouped by context - used by API - deprecated - 
  # MUST CHANGE JS to use the new method valid_translations_with_rules
  ###########################################################################
  def find_all_valid_translations(translations)
    if translations.empty?
      return {:id => self.id, :key => self.key, :label => self.label, :original => true}
    end
    
    # if the first translation does not depend on any of the context rules
    # use it... we don't care about the rest of the rules.
    if translations.first.rules_hash.blank?
      return {:id => self.id, :key => self.key, :label => translations.first.label}
    end
    
    # build a context hash for every kind of context rules combinations
    # only the first one in the list should be used
    context_hash_matches = {}
    valid_translations = []
    translations.each do |translation|
      context_key = translation.rules_hash || ""
      next if context_hash_matches[context_key]
      context_hash_matches[context_key] = true
      if translation.rules_definitions
        valid_translations << {:label => translation.label, :context => translation.rules_definitions.dup}
      else
        valid_translations << {:label => translation.label}
      end
    end

    # always add the default one at the end, so if none of the rules matched, use the english one
    valid_translations << {:label => self.label} unless context_hash_matches[""]
    {:id => self.id, :key => self.key, :labels => valid_translations}
  end
  ###########################################################################

  def find_first_valid_translation(language, token_values)
    cached_translations_for_language(language).each do |translation|
      return translation if translation.matches_rules?(token_values)
    end
    
    nil
  end

  # language fallback approach
  # each language can have a fallback language
  def find_first_valid_translation_for_language(language, token_values)
    translation = find_first_valid_translation(language, token_values)
    return [language, translation] if translation

    if Tr8nClientSdk::Config.enable_fallback_languages?
      # recursevily go into the fallback language and look there
      # no need to go to the default language - there obviously won't be any translations for it
      # unless you really won't to keep the keys in the text, and translate the default language
      if language.fallback_language and not language.fallback_language.default?
        return find_first_valid_translation_for_language(language.fallback_language, token_values)
      end
    end  
    
    [language, nil]
  end
  
  # translator fallback approach
  # each translator can have a fallback language, which may have a fallback language
  def find_first_valid_translation_for_translator(language, translator, token_values)
    translation = find_first_valid_translation(language, token_values)
    return [language, translation] if translation
    
    if translator.fallback_language and not translator.fallback_language.default?
      return find_first_valid_translation_for_language(translator.fallback_language, token_values)
    end

    [language, nil]
  end

  # new way of getting translations for an API call
  # TODO: switch to the new sync_hash method
  def valid_translations_with_rules(language = Tr8nClientSdk::Config.current_language)
    translations = cached_translations_for_language(language)
    return [] if translations.empty?
    
    # if the first translation does not depend on any of the context rules
    # use it... we don't care about the rest of the rules.
    return [{:label => translations.first.label}] if translations.first.rules_hash.blank?
    
    # build a context hash for every kind of context rules combinations
    # only the first one in the list should be used
    context_hash_matches = {}
    valid_translations = []
    translations.each do |translation|
      context_key = translation.rules_hash || ""
      next if context_hash_matches[context_key]
      context_hash_matches[context_key] = true
      if translation.rules_definitions
        valid_translations << {:label => translation.label, :context => translation.rules_definitions.dup}
      else
        valid_translations << {:label => translation.label}
      end
    end

    valid_translations
  end

  def translate(language = Tr8nClientSdk::Config.current_language, token_values = {}, options = {})
    if options[:api] # deprecated
      return find_all_valid_translations(cached_translations_for_language(language)) 
    end
    
    if Tr8nClientSdk::Config.disabled? or language.default?
      return substitute_tokens(label, token_values, options.merge(:fallback => false), language).html_safe
    end
    
    if Tr8nClientSdk::Config.enable_translator_language? and Tr8nClientSdk::Config.current_user_is_translator?
      translation_language, translation = find_first_valid_translation_for_translator(language, Tr8nClientSdk::Config.current_translator, token_values)
    else  
      translation_language, translation = find_first_valid_translation_for_language(language, token_values)
    end
    
    # if you want to present the label in it's sanitized form - for the phrase list
    if options[:default_language] 
      return decorate_translation(language, sanitized_label, translation != nil, options).html_safe
    end
    
    if translation
      translated_label = substitute_tokens(translation.label, token_values, options, language)
      return decorate_translation(language, translated_label, translation != nil, options.merge(:fallback => (translation_language != language))).html_safe
    end

    # no translation found  
    translated_label = substitute_tokens(label, token_values, options, Tr8nClientSdk::Config.default_language)
    decorate_translation(language, translated_label, translation != nil, options).html_safe  
  end

  ###############################################################
  ## Substitution and Decoration Related Stuff
  ###############################################################

  # this is done when the translations engine is disabled
  def self.substitute_tokens(label, tokens, options = {}, language = Tr8nClientSdk::Config.default_language)
    return label.to_s if options[:skip_substitution] 
    Tr8nClientSdk::TranslationKey.new(:label => label.to_s).substitute_tokens(label.to_s, tokens, options, language)
  end

  def allowed_token?(token)
    tokenized_label.allowed_token?(token)
  end

  def substitute_tokens(translated_label, token_values, options = {}, language = Tr8nClientSdk::Config.current_language)
    processed_label = translated_label.to_s.dup

    # substitute all data tokens
    Tr8nClientSdk::TokenizedLabel.new(processed_label).data_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(processed_label, token_values, options, language) 
    end

    # substitute all decoration tokens
    Tr8nClientSdk::TokenizedLabel.new(processed_label).decoration_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(processed_label, token_values, options, language) 
    end
    
    processed_label
  end
  
  def level
    return 0 if super.nil?
    super
  end
  
  def can_be_translated?(translator = nil)
    translator ||= (Tr8nClientSdk::Config.current_user_is_translator? ? Tr8nClientSdk::Config.current_translator : nil)
    if translator 
      return false if locked? and not translator.manager? 
      translator_level = translator.level
    else   
      return false if locked?
      translator_level = 0
    end
    translator_level >= level
  end
  
  def decorate_translation(language, translated_label, translated = true, options = {})
    return translated_label if options[:skip_decorations]
    return translated_label if Tr8nClientSdk::Config.current_user_is_guest?
    return translated_label unless Tr8nClientSdk::Config.current_user_is_translator?
    return translated_label if Tr8nClientSdk::Config.current_translator.blocked?
    return translated_label unless Tr8nClientSdk::Config.current_translator.enable_inline_translations?
    return translated_label unless can_be_translated?
    return translated_label if self.language == language
    return translated_label if locked?(language) and not Tr8nClientSdk::Config.current_translator.manager?

    classes = ['tr8n_translatable']
    
    if locked?(language)
      classes << 'tr8n_locked'
    elsif language.default?
      classes << 'tr8n_not_translated'
    elsif options[:fallback] 
      classes << 'tr8n_fallback'
    else
      classes << (translated ? 'tr8n_translated' : 'tr8n_not_translated')
    end  

    html = "<tr8n class='#{classes.join(' ')}' translation_key_id='#{id}'>"
    html << translated_label
    html << "</tr8n>"
    html
  end
 
end
