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
  module ActionControllerExtension

    def self.included(base)
      base.send(:include, Tr8nClientSdk::ActionCommonMethods) 
      base.send(:include, InstanceMethods) 
      base.before_filter :tr8n_init_client_sdk
      base.after_filter :tr8n_reset_client_sdk
    end

    module InstanceMethods

      def tr8n_browser_accepted_locales
        @tr8n_browser_accepted_locales ||= Tr8n::Utils.browser_accepted_locales(request)
      end

      def tr8n_user_preferred_locale
        tr8n_browser_accepted_locales.each do |locale|
          next unless Tr8n.session.application.locales.include?(locale)
          return locale
        end
        Tr8n.config.default_locale
      end
      
      # Overwrite this method in a controller to assign a custom source for all views
      def tr8n_source
        "/#{controller_name}/#{action_name}"
      rescue
        self.class.name
      end

      # Overwrite this method in a controller to assign a custom component for all views
      def tr8n_component
        nil
      end  

      def tr8n_init_current_locale
        self.send(Tr8n.config.current_locale_method) if Tr8n.config.current_locale_method
      rescue
        # fallback to the default session based locale implementation
        # choose the first language from the accepted languages header
        session[:locale] = tr8n_user_preferred_locale unless session[:locale]
        session[:locale] = params[:locale] if params[:locale]
        session[:locale]
      end

      def tr8n_init_current_user
        self.send(Tr8n.config.current_user_method) if Tr8n.config.current_user_method
      rescue
        nil
      end

      def tr8n_init_client_sdk
        return if Tr8n.config.disabled?

        Tr8n.logger.info("Initializing request...")
        @tr8n_started_at = Time.now

        Tr8n.session.init

        translator = nil

        cookie_name = "tr8n_#{tr8n_application.key}"
        if request.cookies[cookie_name]
          Tr8n.logger.info("Cookie exists:")
          cookie_params = Tr8n::Utils.decode_and_verify_params(request.cookies[cookie_name], tr8n_application.secret)
          Tr8n.logger.info(cookie_params.inspect)
          locale = cookie_params["locale"]
          translator = Tr8n::Translator.new(cookie_params["translator"].merge(:application => tr8n_application)) unless cookie_params["translator"].nil?
        else
          Tr8n.logger.info("Cookie does not exist")
        end

        Tr8n.session.current_user = tr8n_init_current_user
        Tr8n.session.current_translator = translator
        Tr8n.session.current_language = tr8n_application.language(locale || tr8n_init_current_locale)
        Tr8n.session.current_source = tr8n_source
        Tr8n.session.current_component = tr8n_component
      end

      def tr8n_reset_client_sdk
        @tr8n_finished_at = Time.now

        Tr8n.logger.info("Resetting request...")
        tr8n_application.submit_missing_keys
        Tr8n.session.reset

        Tr8n.logger.info("Request took #{@tr8n_finished_at - @tr8n_started_at} mls")
      end

    end
  end
end
