#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
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
    thread_safe_attributes :application, :current_user, :current_language, :current_translator, :current_source, :current_component
    thread_safe_attributes :block_options

    def root
      Rails.root
    end

    def env
      Rails.env
    end

    def defaults
      @defaults ||= HashWithIndifferentAccess.new(Tr8n::Utils.load_yaml("#{root}/config/tr8n/config.yml", env))
    end

    def default_data_tokens
      @default_data_tokens ||= Tr8n::Utils.load_yaml("#{root}/config/tr8n/tokens/data.yml")
    end

    def default_decoration_tokens
      @default_decoration_tokens ||= Tr8n::Utils.load_yaml("#{root}/config/tr8n/tokens/decorations.yml")
    end

    def init_request(user, translator, locale, source = nil, component = nil)
      self.current_user = user
      self.current_translator = translator
      self.current_language = (application.language(locale) || default_language)
      self.current_source = source
      self.current_component = component

      # # register source with component
      # unless component.nil?
      #   set_component(application.component_by_key(component))
      #   current_component.register_source(current_source)
      # else
      #   set_component(nil)
      # end
    end

    #def current_user_is_authorized_to_view_component?(component = current_component)
    #  return true if component.nil? # no component present, so be it
    #  component = application.component_by_key(component.to_s) if component.is_a?(Symbol)
    #
    #  return true unless component.restricted?
    #  return false unless Tr8n.config.current_translator
    #  return true if component.translator_authorized?
    #
    #  false
    #end
    #
    #def current_user_is_authorized_to_view_language?(component = current_component, language = current_language)
    #  return true if component.nil? # no component present, so be it
    #  component = application.component_by_key(component.to_s) if component.is_a?(Symbol)
    #
    #  # if Tr8n.config.current_translator
    #  #   return true if component.translator_authorized?
    #  # end
    #
    #  # component.component_languages.each do |cl|
    #  #   return cl.live? if cl.language_id == language.id
    #  # end
    #
    #  true
    #end

    def decorator_class
      Tr8n::Decorators::Html
    end

    def reset_request
      reset
    end

    def url_for(path)
      "#{defaults["host"]}#{path}"
    end

    #########################################################
    # Site Info
    #########################################################
    def site_info
      defaults[:site_info]
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

  end
end
