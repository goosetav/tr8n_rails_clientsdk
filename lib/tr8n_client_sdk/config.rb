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

require 'json'

module Tr8nClientSdk
  class Config

    #########################################################
    # Basic Stuff
  
    # initializes language, user and translator
    # the variables are kept in a thread safe form throughout the request
    def self.init(site_current_locale, site_current_user = nil, site_current_translator = nil, source = nil, component = nil)
      Thread.current[:tr8n_current_language]   = Tr8nClientSdk::Language.for(site_current_locale) || default_language
      Thread.current[:tr8n_current_user]       = site_current_user
      Thread.current[:tr8n_current_translator] = site_current_translator
      Thread.current[:tr8n_current_source]     = Tr8nClientSdk::TranslationSource.find_or_create(source || "undefined")

      # register source with component
      unless component.nil?
        Thread.current[:tr8n_current_component]  = Tr8nClientSdk::Component.find_or_create(component) 
        Tr8nClientSdk::ComponentSource.find_or_create(current_component, current_source)
      else
        Thread.current[:tr8n_current_component]  = nil
      end

      Thread.current[:tr8n_block_options]      = []
    end
  
    def self.current_user
      Thread.current[:tr8n_current_user]
    end

    def self.current_source
      Thread.current[:tr8n_current_source] ||= Tr8nClientSdk::TranslationSource.find_or_create("undefined")
    end
  
    def self.set_source(source)
      Thread.current[:tr8n_current_source]     = Tr8nClientSdk::TranslationSource.find_or_create(source)
    end

    def self.current_component
      Thread.current[:tr8n_current_component]
    end  

    def self.set_component(component)
      Thread.current[:tr8n_current_component]  = Tr8nClientSdk::Component.find_or_create(component)
    end

    def self.current_language
      Thread.current[:tr8n_current_language] ||= default_language
    end
  
    def self.set_language(language)
      Thread.current[:tr8n_current_language] = language
    end

    def self.current_user_is_translator?
      Thread.current[:tr8n_current_translator] != nil
    end
  
    def self.current_user_is_authorized_to_view_component?(component = current_component)
      return true if component.nil? # no component present, so be it

      component = Tr8nClientSdk::Component.find_by_key(component.to_s) if component.is_a?(Symbol)

      return true unless component.restricted?
      return false unless Tr8nClientSdk::Config.current_user_is_translator?
      return true if component.translator_authorized?

      if Tr8nClientSdk::Config.current_user_is_admin?
        Tr8nClientSdk::ComponentTranslator.find_or_create(component, Tr8nClientSdk::Config.current_translator)
        return true
      end
      
      false
    end

    def self.current_user_is_authorized_to_view_language?(component = current_component, language = current_language)
      return true if component.nil? # no component present, so be it

      component = Tr8nClientSdk::Component.find_by_key(component.to_s) if component.is_a?(Symbol)

      if Tr8nClientSdk::Config.current_user_is_translator? 
        return true if component.translators.include?(Tr8nClientSdk::Config.current_translator)
      end

      component.component_languages.each do |cl|
        return cl.live? if cl.language_id == language.id 
      end
      
      true
    end

    # when this method is called, we create the translator record right away
    # and from this point on, will track the user
    # this can happen any time user tries to translate something or enables inline translations
    def self.current_translator
      Thread.current[:tr8n_current_translator] ||= Tr8nClientSdk::Translator.register
    end
  
    def self.set_translator(translator)
      Thread.current[:tr8n_current_translator]  = translator
    end

    def self.default_language
      return Tr8nClientSdk::Language.new(:locale => default_locale) if disabled?
      @default_language ||= Tr8nClientSdk::Language.for(default_locale) || Tr8nClientSdk::Language.new(:locale => default_locale)
    end
    
    # only one allowed per system
    def self.system_translator
      @system_translator ||= Tr8nClientSdk::Translator.where(:level => system_level).first || Tr8nClientSdk::Translator.create(:user_id => 0, :level => system_level)
    end
  
    def self.reset!
      # thread based variables
      Thread.current[:tr8n_current_language]  = nil
      Thread.current[:tr8n_current_user] = nil
      Thread.current[:tr8n_current_translator] = nil
      Thread.current[:tr8n_block_options]  = nil
      Thread.current[:tr8n_current_source] = nil
      Thread.current[:tr8n_current_component] = nil
    end

    def self.models
      [ 
         Tr8nClientSdk::LanguageRule, Tr8nClientSdk::LanguageUser, Tr8nClientSdk::Language,
         Tr8nClientSdk::LanguageCase, Tr8nClientSdk::LanguageCaseValueMap, Tr8nClientSdk::LanguageCaseRule,
         Tr8nClientSdk::TranslationKey, Tr8nClientSdk::RelationshipKey, Tr8nClientSdk::ConfigurationKey, 
         Tr8nClientSdk::TranslationKeySource, Tr8nClientSdk::TranslationKeyLock,
         Tr8nClientSdk::TranslationSource, Tr8nClientSdk::TranslationDomain, Tr8nClientSdk::TranslationSourceLanguage, 
         Tr8nClientSdk::Translation, Tr8nClientSdk::Translator, Tr8nClientSdk::Application, 
         Tr8nClientSdk::Component, Tr8nClientSdk::ComponentSource, Tr8nClientSdk::ComponentTranslator, Tr8nClientSdk::ComponentLanguage,
      ]    
    end

    def self.guid
      (0..16).to_a.map{|a| rand(16).to_s(16)}.join
    end
  
    def self.root
      Rails.root
    end
  
    def self.env
      Rails.env
    end

    def self.host
      config["host"]
    end

    def self.url_for(path)
      "//#{config["host"]}#{path}"
    end

    # json support
    def self.load_json(file_path)
      json = JSON.parse(File.read("#{root}#{file_path}"))
      return HashWithIndifferentAccess.new(json) if json.is_a?(Hash)
      map = {"map" => json}
      HashWithIndifferentAccess.new(map)[:map]
    end

    def self.load_yml(file_path, for_env = env)
      yml = YAML.load_file("#{root}#{file_path}")
      yml = yml['defaults'].rmerge(yml[for_env] || {}) unless for_env.nil?
      HashWithIndifferentAccess.new(yml)
    end
  
    def self.dump_config
      save_to_yaml("config.yml.dump", config)
    end
  
    def self.config
      @config ||= load_yml("/config/tr8n_client_sdk/config.yml")
    end

    def self.default_decoration_tokens
      @default_decoration_tokens ||= load_yml("/config/tr8n_client_sdk/tokens/decorations.yml", nil)
    end

    def self.default_data_tokens
      @default_data_tokens ||= load_yml("/config/tr8n_client_sdk/tokens/data.yml", nil)
    end

    def self.enabled?
      config[:enable_tr8n] 
    end
  
    def self.disabled?
      not enabled?
    end

    def self.enable_inline_translations?
      config[:enable_inline_translations]
    end
  
    def self.enable_language_cases?
      config[:enable_language_cases]
    end
  
    def self.enable_key_caller_tracking?
      config[:enable_key_caller_tracking]
    end

    def self.enable_language_flags?
      config[:enable_language_flags]
    end

    def self.enable_translator_language?
      config[:enable_translator_language]
    end

    def self.enable_admin_translations?
      config[:enable_admin_translations]
    end

    def self.enable_admin_inline_mode?
      config[:enable_admin_inline_mode]
    end

    #########################################################
    # Translator Roles and Levels
    #########################################################
    def self.translator_roles
      config[:translator_roles]
    end

    def self.translator_levels
      @translator_levels ||= begin
        levels = HashWithIndifferentAccess.new
        translator_roles.each do |key, val|
          levels[val] = key
        end
        levels
      end
    end

    def self.manager_level
      1000
    end

    def self.application_level
      100000
    end

    def self.system_level
      1000000
    end

    def self.admin_level
      100000000
    end

    def self.default_translation_key_level
      config[:default_translation_key_level] || 0
    end

    #########################################################
    # Config Sections
    #########################################################

    def self.localization
      config[:localization]
    end

    def self.api
      config[:api]
    end

    #########################################################
    # Caching
    #########################################################
    def self.caching
      config[:caching]
    end

    def self.enable_caching?
      caching[:enabled]
    end

    def self.cache_adapter
      caching[:adapter]
    end

    def self.cache_store
      caching[:store]
    end

    def self.cache_version
      caching[:version]
    end
    #########################################################

    #########################################################
    # Logger
    #########################################################
    def self.logger
      config[:logger]
    end

    def self.enable_logger?
      logger[:enabled]
    end

    def self.log_path
      logger[:log_path]
    end

    #########################################################
  
    #########################################################
    # Site Info
    #########################################################
    def self.site_info
      config[:site_info]
    end

    def self.site_title
      site_info[:title]
    end

    def self.base_url
      site_info[:base_url]
    end

    def self.default_url
      site_info[:default_url]
    end

    def self.contact_email
      site_info[:contact_email]
    end
  
    def self.default_locale
      return block_options[:default_locale] if block_options[:default_locale]
      site_info[:default_locale]
    end

    def self.default_admin_locale
      return block_options[:default_admin_locale] if block_options[:default_admin_locale]
      site_info[:default_admin_locale]
    end

    def self.current_locale_method
      site_info[:current_locale_method]
    end

    #########################################################
    # site user info
    # The following methods could be overloaded in the initializer
    #########################################################
    def self.site_user_info
      site_info[:user_info]
    end

    def self.current_user_method
      site_user_info[:current_user_method]
    end
  
    def self.user_class_name
      site_user_info[:class_name]
    end

    def self.user_class
      user_class_name.constantize
    end

    def self.user_id(user)
      return 0 unless user
      user.send(site_user_info[:methods][:id])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch user id: #{ex.to_s}")
      0
    end

    def self.user_name(user)
      return "Unknown user" unless user
      user.send(site_user_info[:methods][:name])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Invalid user"
    end

    def self.user_email(user)
      user.send(site_user_info[:methods][:email])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Unknown user"
    end

    def self.user_gender(user)
      return "unknown" unless user
      user.send(site_user_info[:methods][:gender])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "unknown"
    end

    def self.user_mugshot(user)
      return silhouette_image unless user
      user.send(site_user_info[:methods][:mugshot])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} image: #{ex.to_s}")
      silhouette_image
    end

    def self.user_link(user)
      return "/tr8n" unless user
      user.send(site_user_info[:methods][:link])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} link: #{ex.to_s}")
      "/tr8n"
    end

    def self.user_locale(user)
      return default_locale unless user
      user.send(site_user_info[:methods][:locale])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} locale: #{ex.to_s}")
      default_locale
    end

    def self.admin_user?(user = Tr8nClientSdk::Config.current_user)
      return false unless user
      user.send(site_user_info[:methods][:admin])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} admin flag: #{ex.to_s}")
      false
    end

    def self.current_user_is_admin?
      admin_user?
    end

    def self.current_user_is_manager?
      return false unless current_user_is_translator?
      return true if current_user_is_admin?
      current_translator.manager?
    end

    def self.guest_user?(user = Tr8nClientSdk::Config.current_user)
      return true unless user
      user.send(site_user_info[:methods][:guest])
    rescue Exception => ex
      Tr8nClientSdk::Logger.error("Failed to fetch #{user_class_name} guest flag: #{ex.to_s}")
      true
    end
  
    def self.current_user_is_guest?
      guest_user?
    end
  
    def self.silhouette_image
      "/assets/tr8n/photo_silhouette.gif"
    end

    def self.system_image
      "/assets/tr8n/photo_system.gif"
    end
  
    #########################################################
    # RULES ENGINE
    #########################################################
    def self.rules_engine
      config[:rules_engine]
    end

    def self.language_rule_classes
      @language_rule_classes ||= rules_engine[:language_rule_classes].collect{|lrc| lrc.constantize}
    end

    def self.language_rule_dependencies
      @language_rule_dependencies ||= begin
        depts = HashWithIndifferentAccess.new
        language_rule_classes.each do |cls|
          if depts[cls.dependency]
            raise Tr8nClientSdk::Exception.new("The same dependency key #{cls.dependency} has been registered for multiple rules. This is not allowed.")
          end  
          depts[cls.dependency] = cls
        end
        depts
      end
    end

    def self.universal_language_rules
      @universal_language_rules ||= begin
        urs = []
        language_rule_classes.each do |cls|
          next unless cls.suffixes.is_a?(String)
          urs << cls if cls.suffixes == "*"
        end
        urs
      end
    end

    def self.language_rule_suffixes
      @language_rule_suffixes ||= begin
        sfx = {}
        language_rule_classes.each do |cls|
          next unless cls.suffixes.is_a?(Array)
          cls.suffixes.each do |suffix|
            if suffix.index("_")
              raise Tr8nClientSdk::Exception.new("Incorrect rule suffix: #{suffix}. Suffix may not have '_' in it.")
            end
            sfx[suffix] ||= []
            sfx[suffix] << cls
          end
        end
        sfx
      end
    end

    def self.language_rules_for_suffix(suffix)
      suffix_rules = language_rule_suffixes[suffix] || []
      suffix_rules + universal_language_rules
    end

    def self.allow_nil_token_values?
      rules_engine[:allow_nil_token_values]
    end
  
    def self.data_token_classes
      @data_token_classes ||= rules_engine[:data_token_classes].collect{|tc| tc.constantize}
    end

    def self.decoration_token_classes
      @decoration_token_classes ||= rules_engine[:decoration_token_classes].collect{|tc| tc.constantize}
    end
  
    def self.viewing_user_token_for(label)
      Tr8nClientSdk::Tokens::DataToken.new(label, "{#{rules_engine[:viewing_user_token]}:gender}")
    end

    def self.translation_threshold
      rules_engine[:translation_threshold]
    end

    def self.default_rank_styles
      @default_rank_styles ||= begin
        styles = {}
        rules_engine[:translation_rank_styles].each do |key, value|
          range = Range.new(*(key.to_s.split("..").map{|v| v.to_i}))
          styles[range] = value
        end
        styles  
      end
    end

    # get rules for specified locale, or get default language rules
    def self.load_default_rules(rules_type, locale = default_locale)
      @default_rules ||= {}
      @default_rules[rules_type] ||= load_yml("/config/tr8n/rules/default_#{rules_type}_rules.yml", nil)
      rules_for_locale = @default_rules[rules_type][locale.to_s]
    
      return rules_for_locale.values unless rules_for_locale.nil?
      return [] if @default_rules[rules_type][default_locale].nil?
      @default_rules[rules_type][default_locale].values
    end

    def self.default_gender_rules(locale = default_locale)
      load_default_rules("gender", locale)
    end

    def self.default_gender_list_rules(locale = default_locale)
      load_default_rules("gender_list", locale)
    end

    def self.default_list_rules(locale = default_locale)
      load_default_rules("list", locale)
    end

    def self.default_numeric_rules(locale = default_locale)
      load_default_rules("numeric", locale)
    end

    def self.default_date_rules(locale = default_locale)
      load_default_rules("date", locale)
    end

    def self.default_value_rules(locale = default_locale)
      load_default_rules("value", locale)
    end

    def self.default_language_cases_for(locale = default_locale)
      @default_cases ||= load_yml("/config/tr8n/rules/default_language_cases.yml", nil)
      return [] unless @default_cases[locale.to_s]
      @default_cases[locale.to_s].values
    end

    def self.country_from_ip(remote_ip)
      default_country = config["default_country"] || "USA"
      return default_country unless Tr8nClientSdk::IpAddress.routable?(remote_ip)
      location = Tr8nClientSdk::IpLocation.find_by_ip(remote_ip)
      (location and location.cntry) ? location.cntry : default_country
    end

    #########################################################
    # LOCALIZATION
    #########################################################
    def self.strftime_symbol_to_token(symbol)
      {
        "%a" => "{short_week_day_name}",
        "%A" => "{week_day_name}",
        "%b" => "{short_month_name}",
        "%B" => "{month_name}",
        "%p" => "{am_pm}",
        "%d" => "{days}",
        "%e" => "{day_of_month}", 
        "%j" => "{year_days}",
        "%m" => "{months}",
        "%W" => "{week_num}",
        "%w" => "{week_days}",
        "%y" => "{short_years}",
        "%Y" => "{years}",
        "%l" => "{trimed_hour}", 
        "%H" => "{full_hours}", 
        "%I" => "{short_hours}", 
        "%M" => "{minutes}", 
        "%S" => "{seconds}", 
        "%s" => "{since_epoch}"
      }[symbol]
    end
  
    def self.default_day_names
      localization[:default_day_names]
    end

    def self.default_abbr_day_names
      localization[:default_abbr_day_names]
    end

    def self.default_month_names
      localization[:default_month_names]
    end

    def self.default_abbr_month_names
      localization[:default_abbr_month_names]
    end
  
    def self.default_date_formats
      localization[:custom_date_formats]
    end

    #########################################################
    ### BLOCK OPTIONS
    #########################################################
    def self.block_options
      (Thread.current[:tr8n_block_options] || []).last || {}
    end

    def self.current_source_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return Tr8nClientSdk::TranslationSource.find_or_create(opts[:source]) unless opts[:source].blank?
      end
      nil
    end

    def self.current_component_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return Tr8nClientSdk::Component.find_or_create(opts[:component]) unless opts[:component].blank?
      end
      Tr8nClientSdk::Config.current_component
    end

  end
end
