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

class Tr8n::Source < Tr8n::Base
  attributes :source, :url, :name, :description
  
  def self.normalize_source(url)
    return nil if url.blank?
    uri = URI.parse(url)
    path = uri.path
    return "/" if uri.path.blank?
    return path if path == "/"

    # always must start with /
    path = "/#{path}" if path[0] != "/"
    # should not end with /
    path = path[0..-2] if path[-1] == "/"
    path
  end

  def self.cache_key(source)
    "source_[#{source.to_s}]"
  end

  def cache_key
    self.class.cache_key(Tr8n::Config.current_application, source)
  end
  
  def self.fetch_or_register(source)
    return source if source.is_a?(Tr8n::Source)

    Tr8n::Cache.fetch(cache_key(source)) do 
      post("source/register", {:source => source}, {:fetch => true})
    end  
  end

  def cache_key_for_language(language = Tr8n::Config.current_language)
    "translations_for_[#{self.source}]_[#{language.locale}]"
  end

  def cache(language = Tr8n::Config.current_language)
    @cache ||= {}
    @cache[language.locale] ||= begin
      Tr8n::Cache.fetch(cache_key_for_language(language)) do 
        keys_with_translations = get("source/translations", {:source => source, :locale => language.locale}, {:class => Tr8n::TranslationKey})
        hash = {}
        keys_with_translations.each do |tkey|
          hash[tkey.key] = tkey
        end
        hash
      end
    end
  end

  def clear_cache_for_language(language = Tr8n::Config.current_language)
    Tr8n::Cache.delete(cache_key_for_language(language))
  end

  # TODO: move offline
  def self.register_missing_keys
    return if Tr8n::Config.missing_keys_by_sources.empty?
    params = []
    Tr8n::Config.missing_keys_by_sources.each do |source, keys|
      params << {:source => source, :keys => keys.values.collect{|tkey| tkey.to_api_hash}}
    end 
    post('source/register_keys', {:source_keys => params.to_json}, :method => :post)
  end

end