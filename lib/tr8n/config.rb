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

class Tr8n::Config

  #########################################################
  # Core features
  # Application is a static component in each process 
  def self.app_key
    config["app_key"]
  end

  def self.app_secret
    config["app_secret"]
  end

  def self.application
    @application ||= Tr8n::Application.init(app_key, app_secret)
  end

  def self.init_request(locale, translator, source = nil, component = nil)
    set_translator(translator)
    set_language(application.language_by_locale(locale) || default_language)
    set_source(application.source_by_key(source || "undefined"))
    Thread.current[:tr8n_block_options]           = []

    # register source with component
    unless component.nil?
      set_component(application.component_by_key(component))
      current_component.register_source(current_source)
    else
      set_component(nil)
    end
  end

  def self.current_user
    Thread.current[:tr8n_current_user]
  end

  def self.set_user(user)
    Thread.current[:tr8n_current_user] = user
  end

  def self.current_translator
    Thread.current[:tr8n_current_translator]
  end

  def self.set_translator(translator)
    Thread.current[:tr8n_current_translator] = translator
  end

  def self.current_language
    Thread.current[:tr8n_current_language] ||= default_language
  end

  def self.set_language(language)
    Thread.current[:tr8n_current_language] = language
  end

  def self.current_source
    Thread.current[:tr8n_current_source]
  end

  def self.set_source(source)
    Thread.current[:tr8n_current_source] = source
  end

  def self.current_component
    Thread.current[:tr8n_current_component]
  end  

  def self.set_component(component)
    Thread.current[:tr8n_current_component] = component
  end

  def self.current_user_is_authorized_to_view_component?(component = current_component)
    return true if component.nil? # no component present, so be it
    component = application.component_by_key(component.to_s) if component.is_a?(Symbol)

    return true unless component.restricted?
    return false unless Tr8n::Config.current_translator
    return true if component.translator_authorized?

    false
  end

  def self.current_user_is_authorized_to_view_language?(component = current_component, language = current_language)
    return true if component.nil? # no component present, so be it
    component = application.component_by_key(component.to_s) if component.is_a?(Symbol)

    if Tr8n::Config.current_translator
      return true if component.translator_authorized?
    end

    # component.component_languages.each do |cl|
    #   return cl.live? if cl.language_id == language.id 
    # end
    
    true
  end

  def self.default_language
    return Tr8n::Language.new(:locale => default_locale, :default => true) if disabled?
    @default_language ||= application.language_by_locale(default_locale) 
  end

  def self.reset_request
    # thread based variables
    Thread.current[:tr8n_current_language] = nil
    Thread.current[:tr8n_current_user] = nil
    Thread.current[:tr8n_current_translator] = nil
    Thread.current[:tr8n_block_options]  = nil
    Thread.current[:tr8n_current_source] = nil
    Thread.current[:tr8n_current_component] = nil
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
    @config ||= load_yml("/config/tr8n/config.yml")
  end

  def self.enabled?
    config[:enable_tr8n] 
  end

  def self.disabled?
    not enabled?
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
    Tr8n::Logger.error("Failed to fetch user id: #{ex.to_s}")
    0
  end

  def self.user_name(user)
    return "Unknown user" unless user
    user.send(site_user_info[:methods][:name])
  rescue Exception => ex
    Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
    "Invalid user"
  end

  def self.user_gender(user)
    return "unknown" unless user
    user.send(site_user_info[:methods][:gender])
  rescue Exception => ex
    Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
    "unknown"
  end

  def self.guest_user?(user = Tr8n::Config.current_user)
    return true unless user
    user.send(site_user_info[:methods][:guest])
  rescue Exception => ex
    Tr8n::Logger.error("Failed to fetch #{user_class_name} guest flag: #{ex.to_s}")
    true
  end

  def self.current_user_is_guest?
    guest_user?
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
        if depts[cls.key]
          raise Tr8n::Exception.new("The same dependency key #{cls.key} has been registered for multiple rules. This is not allowed.")
        end  
        depts[cls.key] = cls
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
            raise Tr8n::Exception.new("Incorrect rule suffix: #{suffix}. Suffix may not have '_' in it.")
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
    Tr8n::Tokens::DataToken.new(label, "{#{rules_engine[:viewing_user_token]}:gender}")
  end

  def self.translation_threshold
    rules_engine[:translation_threshold]
  end

  #########################################################
  # LOCALIZATION
  #########################################################
  def self.localization
    config[:localization]
  end

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
      return application.source_by_key(opts[:source]) unless opts[:source].blank?
    end
    nil
  end

  def self.current_component_from_block_options
    arr = Thread.current[:tr8n_block_options] || []
    arr.reverse.each do |opts|
      return application.component_by_key(opts[:component]) unless opts[:component].blank?
    end
    Tr8n::Config.current_component
  end

  #########################################################
  # Sharing
  #########################################################

  def self.sign_and_encode_params(params, secret)  
    payload = Base64.encode64(params.merge(:algorithm => 'HMAC-SHA256', :ts => Time.now.to_i).to_json)
    sig = OpenSSL::HMAC.digest('sha256', secret, payload)
    encoded_sig = Base64.encode64(sig)
    URI::encode("#{encoded_sig}.#{payload}")
  end

  def self.decode_and_verify_params(signed_request, secret)  
    signed_request = URI::decode(signed_request)
    # pp :signed_request, signed_request

    encoded_sig, payload = signed_request.split('.', 2)
    # pp :encoded_sig, encoded_sig
    # pp :secret, secret

    sig = Base64.decode64(encoded_sig)

    data = JSON.parse(Base64.decode64(payload))
    # pp :secret, secret

    if data['algorithm'].to_s.upcase != 'HMAC-SHA256'
      raise Tr8n::Exception.new("Bad signature algorithm: %s" % data['algorithm'])
    end
    expected_sig = OpenSSL::HMAC.digest('sha256', secret, payload)
    # pp :expected, expected_sig
    # pp :actual, sig

    # pp data

    # if expected_sig != sig
    #   raise Tr8n::Exception.new("Bad signature")
    # end
    HashWithIndifferentAccess.new(data)
  end

end
