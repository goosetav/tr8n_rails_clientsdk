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
  module ActionControllerExtension

    def self.included(base)
      base.send(:include, Tr8nClientSdk::ActionCommonMethods) 
      base.send(:include, InstanceMethods) 
      base.before_filter :tr8n_init_client_sdk
      base.after_filter :tr8n_reset_client_sdk
    end

    module InstanceMethods

      ######################################################################
      # Author: Iain Hecker
      # reference: http://github.com/iain/http_accept_language
      ######################################################################
      def tr8n_browser_accepted_locales
        @accepted_languages ||= request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).collect do |l|
          l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
          l.split(';q=')
        end.sort do |x,y|
          raise Tr8n::Exception.new("Not correctly formatted") unless x.first =~ /^[a-z\-]+$/i
          y.last.to_f <=> x.last.to_f
        end.collect do |l|
          l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
        end
      rescue 
        []
      end

      def tr8n_user_preffered_locale
        tr8n_browser_accepted_locales.each do |locale|
          lang = Tr8n.config.application.language(locale)
          return locale if lang and lang.enabled?
        end
        Tr8n.config.application.default_language
      end
      
      # Overwrite this method in a controller to assign a custom source for all views
      def tr8n_source
        Tr8n::Source.normalize(request.url)
      rescue
        self.class.name
      end

      # Overwrite this method in a controller to assign a custom component for all views
      def tr8n_component
        nil
      end  

      def tr8n_init_current_locale
        self.send(Tr8n.config.current_locale_method)
      rescue
        # fallback to the default session based locale implementation
        # choose the first language from the accepted languages header
        session[:locale] = tr8n_user_preffered_locale unless session[:locale]
        session[:locale] = params[:locale] if params[:locale]
        session[:locale]
      end

      def tr8n_init_current_user
        self.send(Tr8n.config.current_user_method)
      end

      def tr8n_init_client_sdk
        return unless Tr8n.config.enabled?

        tr8n_application.update_cache_version

        cookie_name = "tr8n_#{tr8n_application.key}"
        if request.cookies[cookie_name]
          cookie_params = Tr8n.config.decode_and_verify_params(request.cookies[cookie_name], Tr8n.config.app_secret)  
          locale = cookie_params["locale"]
          translator = Tr8n::Translator.new(cookie_params["translator"].merge(:application => tr8n_application)) unless cookie_params["translator"].nil?
        end

        locale ||= tr8n_init_current_locale
        user = tr8n_init_current_user

        Tr8n.config.init_request(locale, translator, tr8n_source, tr8n_component)
        
        # register component and verify that the current user is authorized to view it
        # unless Tr8n.config.current_user_is_authorized_to_view_component?
        #   trfe("You are not authorized to view this component")
        #   return redirect_to(Tr8n.config.default_url)
        # end

        # unless Tr8n.config.current_user_is_authorized_to_view_language?
        #   Tr8n.config.set_language(Tr8n.config.default_language)
        # end
      end

      def tr8n_reset_client_sdk
        tr8n_application.submit_missing_keys
        # Tr8n.config.current_source.reset_translator_keys
        Tr8n.config.reset_request
      end

    end
  end
end
