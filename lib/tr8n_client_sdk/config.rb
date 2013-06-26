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

module Tr8nClientSdk
  class Config < ::Tr8n::Config
    attributes :application, :default_locale
    thread_safe_attributes :current_user, :current_language, :current_translator, :current_source, :current_component, :current_translation_keys
    thread_safe_attributes :block_options 

    #########################################################
    # Core features
    # Application is a static component in each process 
    def data
      @data ||= load_yml("/config/tr8n/config.yml")
    end

    def host
      data["host"]
    end

    def app_key
      data["app_key"]
    end

    def app_secret
      data["app_secret"]
    end

    def init_application
      self.application = Tr8n::Application.init(host, app_key, app_secret)
    end

    def init_request(locale, translator, source = nil, component = nil)
      self.current_translator = translator
      self.current_language = (application.language_by_locale(locale) || default_language)
      self.current_source = application.source_by_key(source || "undefined")

      # # register source with component
      # unless component.nil?
      #   set_component(application.component_by_key(component))
      #   current_component.register_source(current_source)
      # else
      #   set_component(nil)
      # end
    end

    def current_user_is_authorized_to_view_component?(component = current_component)
      return true if component.nil? # no component present, so be it
      component = application.component_by_key(component.to_s) if component.is_a?(Symbol)

      return true unless component.restricted?
      return false unless Tr8n.config.current_translator
      return true if component.translator_authorized?

      false
    end

    def current_user_is_authorized_to_view_language?(component = current_component, language = current_language)
      return true if component.nil? # no component present, so be it
      component = application.component_by_key(component.to_s) if component.is_a?(Symbol)

      # if Tr8n.config.current_translator
      #   return true if component.translator_authorized?
      # end

      # component.component_languages.each do |cl|
      #   return cl.live? if cl.language_id == language.id 
      # end
      
      true
    end

    def default_language
      return Tr8n::Language.new(:locale => default_locale, :default => true) if disabled?
      @default_language ||= application.language_by_locale(default_locale) 
    end

    def decorator_class
      Tr8n::Decorators::Html
    end

    def reset_request
      reset!
    end

    def root
      Rails.root
    end

    def env
      Rails.env
    end

    def url_for(path)
      "#{data["host"]}#{path}"
    end

    # json support
    def load_json(file_path)
      json = JSON.parse(File.read("#{root}#{file_path}"))
      return HashWithIndifferentAccess.new(json) if json.is_a?(Hash)
      map = {"map" => json}
      HashWithIndifferentAccess.new(map)[:map]
    end

    def load_yml(file_path, for_env = env)
      yml = YAML.load_file("#{root}#{file_path}")
      yml = yml['defaults'].rmerge(yml[for_env] || {}) unless for_env.nil?
      HashWithIndifferentAccess.new(yml)
    end

    def enabled?
      data[:enable_tr8n] 
    end

    def disabled?
      not enabled?
    end

    #########################################################
    # Caching
    #########################################################
    def caching
      data[:caching]
    end

    def enable_caching?
      caching[:enabled]
    end

    def cache_adapter
      caching[:adapter]
    end

    def cache_store
      caching[:store]
    end

    def cache_version
      caching[:version]
    end
    #########################################################

    #########################################################
    # Logger
    #########################################################
    def logger
      data[:logger]
    end

    def enable_logger?
      logger[:enabled]
    end

    def log_path
      logger[:log_path]
    end

    #########################################################

    #########################################################
    # Site Info
    #########################################################
    def site_info
      data[:site_info]
    end

    def site_title
      site_info[:title]
    end

    def base_url
      site_info[:base_url]
    end

    def default_url
      site_info[:default_url]
    end

    def contact_email
      site_info[:contact_email]
    end

    def default_locale
      return block_options[:default_locale] if block_options[:default_locale]
      site_info[:default_locale]
    end

    def default_admin_locale
      return block_options[:default_admin_locale] if block_options[:default_admin_locale]
      site_info[:default_admin_locale]
    end

    def current_locale_method
      site_info[:current_locale_method]
    end

    #########################################################
    # site user info
    # The following methods could be overloaded in the initializer
    #########################################################
    def site_user_info
      site_info[:user_info]
    end

    def current_user_method
      site_user_info[:current_user_method]
    end

    def user_class_name
      site_user_info[:class_name]
    end

    def user_class
      user_class_name.constantize
    end

    def user_id(user)
      return 0 unless user
      user.send(site_user_info[:methods][:id])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch user id: #{ex.to_s}")
      0
    end

    def user_name(user)
      return "Unknown user" unless user
      user.send(site_user_info[:methods][:name])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Invalid user"
    end

    def user_gender(user)
      return "unknown" unless user
      user.send(site_user_info[:methods][:gender])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "unknown"
    end

    def guest_user?(user = Tr8n.config.current_user)
      return true unless user
      user.send(site_user_info[:methods][:guest])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} guest flag: #{ex.to_s}")
      true
    end

    def current_user_is_guest?
      guest_user?
    end

    #########################################################
    # RULES ENGINE
    #########################################################
    # def rules_engine
    #   data[:rules_engine]
    # end

    # def language_rules_for_suffix(suffix)
    #   suffix_rules = language_rule_suffixes[suffix] || []
    #   suffix_rules + universal_language_rules
    # end

    def allow_nil_token_values?
      rules_engine[:allow_nil_token_values]
    end

    # def data_token_classes
    #   @data_token_classes ||= rules_engine[:data_token_classes].collect{|tc| tc.constantize}
    # end

    # def decoration_token_classes
    #   @decoration_token_classes ||= rules_engine[:decoration_token_classes].collect{|tc| tc.constantize}
    # end

    def viewing_user_token_for(label)
      Tr8n::Tokens::Data.new(label, "{#{rules_engine[:viewing_user_token]}:gender}")
    end

    def translation_threshold
      rules_engine[:translation_threshold]
    end

    #########################################################
    # LOCALIZATION
    #########################################################
    def localization
      data[:localization]
    end

    def strftime_symbol_to_token(symbol)
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

    def default_day_names
      localization[:default_day_names]
    end

    def default_abbr_day_names
      localization[:default_abbr_day_names]
    end

    def default_month_names
      localization[:default_month_names]
    end

    def default_abbr_month_names
      localization[:default_abbr_month_names]
    end

    def default_date_formats
      localization[:custom_date_formats]
    end

    #########################################################
    ### BLOCK OPTIONS
    #########################################################
    def block_options
      (Thread.current[:tr8n_block_options] || []).last || {}
    end

    def current_source_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return application.source_by_key(opts[:source]) unless opts[:source].blank?
      end
      nil
    end

    def current_component_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return application.component_by_key(opts[:component]) unless opts[:component].blank?
      end
      Tr8n.config.current_component
    end

    #########################################################
    # Sharing
    #########################################################

    def sign_and_encode_params(params, secret)  
      payload = Base64.encode64(params.merge(:algorithm => 'HMAC-SHA256', :ts => Time.now.to_i).to_json)
      sig = OpenSSL::HMAC.digest('sha256', secret, payload)
      encoded_sig = Base64.encode64(sig)
      URI::encode("#{encoded_sig}.#{payload}")
    end

    def decode_and_verify_params(signed_request, secret)  
      signed_request = URI::decode(signed_request)
      pp :signed_request, signed_request

      encoded_sig, payload = signed_request.split('.', 2)
      pp :encoded_sig, encoded_sig
      pp :secret, secret

      sig = Base64.decode64(encoded_sig)

      data = JSON.parse(Base64.decode64(payload))
      # pp :secret, secret

      if data['algorithm'].to_s.upcase != 'HMAC-SHA256'
        raise Tr8n::Exception.new("Bad signature algorithm: %s" % data['algorithm'])
      end
      expected_sig = OpenSSL::HMAC.digest('sha256', secret, payload)
      # pp :expected, expected_sig
      # pp :actual, sig

      pp data

      # if expected_sig != sig
      #   raise Tr8n::Exception.new("Bad signature")
      # end
      HashWithIndifferentAccess.new(data)
    end

  end
end
