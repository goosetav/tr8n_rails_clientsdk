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

class Tr8n::Application < Tr8n::Base
  attributes :key, :secret, :name, :description, :definition, :languages, :version, :updated_at

  def self.init(key, secret)
    app = get("application", {:client_id => key, :definition => true}, :class => Tr8n::Application)    
    app.key = key
    app.secret = secret
    app
  end

  def initialize(attrs = {})
    super
    if attrs['languages']
      self.languages = attrs['languages'].collect{ |l| Tr8n::Language.new(l) }
    end
    unless attrs['definition']
      self.definition = {}
    end
  end

  def update_cache_version
    return unless updated_at.nil? 
    return if updated_at and updated_at > (Time.now - 1.hour)
    
    # version = get("application/version")
    # Tr8n::Cache.set_version(version)
  end

  def reset!
    @language_by_locale = nil
    @featured_languages = nil
    @sources = nil
    @traslation_keys_by_language = nil
  end

  def language_by_locale(locale)
    @language_by_locale ||= begin
      langs = {}
      languages.each do |lang|      
        langs[lang.locale] = lang
      end
      langs
    end
    return @language_by_locale[locale] if @language_by_locale[locale]

    # for translator languages will continue to build application cache
    @language_by_locale[locale] = get("language", {:locale => locale}, :class => Tr8n::Language)
    @language_by_locale[locale]
  end

  def featured_languages
    @featured_languages ||= get("application/featured_locales").collect{ |locale| language_by_locale(locale) }
  end
 
  def translators
    Tr8n::Cache.fetch("application_translators") do 
      get("application/translators")
    end
  end

  def components
    Tr8n::Cache.fetch("application_components") do 
      get("application/components")
    end
  end

  def default_decoration_tokens
    definition["default_decoration_tokens"]
  end

  def default_data_tokens
    definition["default_data_tokens"]
  end

  def enable_language_cases?
    # self.definition["language_cases_enabled"]
    Tr8n::Config.config[:enable_language_cases]
  end

  def enable_language_flags?
    # self.definition["language_flags_enabled"]
    Tr8n::Config.config[:enable_language_flags]
  end

  def default_data_tokens
    @default_data_tokens ||= self.definition["default_data_tokens"].merge(Tr8n::Config.load_yml("/config/tr8n/tokens/data.yml", nil))
  end

  def default_data_token(token)
    default_data_tokens[token.to_s]
  end

  def default_decoration_tokens
    @default_decoration_tokens ||= self.definition["default_decoration_tokens"].merge(Tr8n::Config.load_yml("/config/tr8n/tokens/decoration.yml", nil))
  end

  def default_decoration_token(token)
    default_decoration_tokens[token.to_s]
  end

  def rules
    self.definition["rules"]
  end

  def sources
    @sources ||= {}
  end

  def source_by_key(key)
    @sources ||= {}
    @sources[key] ||= post("source/register", {:source => key}, {:class => Tr8n::Source})
  end

  def traslation_key_by_language_and_hash(language, hash)
    @traslation_keys_by_language ||= {}
    @traslation_keys_by_language[language.locale] ||= {}
    @traslation_keys_by_language[language.locale][hash]
  end

  def register_translation_key(language, tkey)
    @traslation_keys_by_language ||= {}
    @traslation_keys_by_language[language.locale] ||= {}
    @traslation_keys_by_language[language.locale][tkey.key] = tkey
  end

  def register_missing_key(tkey, source)    
    @missing_keys_by_sources ||= {}
    @missing_keys_by_sources[source.source] ||= {}
    @missing_keys_by_sources[source.source][tkey.key] ||= tkey
  end

  def submit_missing_keys
    return if @missing_keys_by_sources.nil? or @missing_keys_by_sources.empty?
    params = []
    @missing_keys_by_sources.each do |source, keys|
      params << {:source => source, :keys => keys.values.collect{|tkey| tkey.to_api_hash(:label, :description, :locale, :level)}}
      source_by_key(source).reset
    end 
    post('source/register_keys', {:source_keys => params.to_json}, :method => :post)
    @missing_keys_by_sources = nil
  end

end
