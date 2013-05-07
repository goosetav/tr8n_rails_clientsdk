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
      base.send(:include, InstanceMethods) 
      base.before_filter :init_tr8n_client_sdk
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
          raise Tr8nClientSdk::Exception.new("Not correctly formatted") unless x.first =~ /^[a-z\-]+$/i
          y.last.to_f <=> x.last.to_f
        end.collect do |l|
          l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
        end
      rescue 
        []
      end

      def tr8n_user_preffered_locale
        tr8n_browser_accepted_locales.each do |locale|
          lang = Tr8nClientSdk::Language.for(locale)
          return locale if lang and lang.enabled?
        end
        Tr8nClientSdk::Config.default_locale
      end

      def tr8n_request_remote_ip
        @remote_ip ||= if request.env['HTTP_X_FORWARDED_FOR']
          request.env['HTTP_X_FORWARDED_FOR'].split(',').first
        else
          request.remote_ip
        end
      end
      
      def tr8n_source
        "#{self.class.name.underscore.gsub("_controller", "")}/#{self.action_name}"
      rescue
        self.class.name
      end

      def tr8n_component
        nil
      end  

      def tr8n_init_current_locale
        self.send(Tr8nClientSdk::Config.current_locale_method)
      rescue
        # fallback to the default session based locale implementation
        # choose the first language from the accepted languages header
        session[:locale] = tr8n_user_preffered_locale unless session[:locale]
        session[:locale] = params[:locale] if params[:locale]
        session[:locale]
      end

      def tr8n_init_current_user
        self.send(Tr8nClientSdk::Config.current_user_method)
      end

      def init_tr8n_client_sdk
        return unless Tr8nClientSdk::Config.enabled?

        req = request.cookies["tr8n_signed_request"]        
        if req
          elements = req.split(';')
          locale = elements[0]
          if elements.size > 1
            translator = Tr8nClientSdk::Translator.find(elements[1])
          end
        end

        locale ||= tr8n_init_current_locale
        user = tr8n_init_current_user
        translator ||= Tr8nClientSdk::Translator.for(user)

        # initialize request thread variables
        Tr8nClientSdk::Config.init(locale, user, translator, tr8n_source, tr8n_component)
        
        # for logged out users, fallback onto tr8n_access_key
        if Tr8nClientSdk::Config.current_user_is_guest?  
          tr8n_access_key = params[:tr8n_access_key] || session[:tr8n_access_key]
          unless tr8n_access_key.blank?
            Tr8nClientSdk::Config.set_translator(Tr8nClientSdk::Translator.find_by_access_key(tr8n_access_key))
          end
        end

        # register component and verify that the current user is authorized to view it
        unless Tr8nClientSdk::Config.current_user_is_authorized_to_view_component?
          trfe("You are not authorized to view this component")
          return redirect_to(Tr8nClientSdk::Config.default_url)
        end

        unless Tr8nClientSdk::Config.current_user_is_authorized_to_view_language?
          Tr8nClientSdk::Config.set_language(Tr8nClientSdk::Config.default_language)
        end
      end

      ############################################################
      # There are two ways to call the tr method
      #
      # tr(label, desc = "", tokens = {}, options = {})
      # or 
      # tr(label, {:desc => "", tokens => {},  ...})
      ############################################################
      def tr(label, desc = "", tokens = {}, options = {})

        return label if label.tr8n_translated?

        if desc.is_a?(Hash)
          options = desc
          tokens  = options[:tokens] || {}
          desc    = options[:desc] || ""
        end

        options.merge!(:caller => caller)
        options.merge!(:url => request.url)
        options.merge!(:host => request.env['HTTP_HOST'])

        unless Tr8nClientSdk::Config.enabled?
          return Tr8nClientSdk::TranslationKey.substitute_tokens(label, tokens, options)
        end

        Tr8nClientSdk::Config.current_language.translate(label, desc, tokens, options)
      end

      # for translating labels
      def trl(label, desc = "", tokens = {}, options = {})
        tr(label, desc, tokens, options.merge(:skip_decorations => true))
      end

      # flash notice
      def trfn(label, desc = "", tokens = {}, options = {})
        flash[:trfn] = tr(label, desc, tokens, options)
      end

      # flash error
      def trfe(label, desc = "", tokens = {}, options = {})
        flash[:trfe] = tr(label, desc, tokens, options)
      end

      # flash error
      def trfw(label, desc = "", tokens = {}, options = {})
        flash[:trfw] = tr(label, desc, tokens, options)
      end

      # for admin translations
      def tra(label, desc = "", tokens = {}, options = {})
        if Tr8nClientSdk::Config.enable_admin_translations?
          if Tr8nClientSdk::Config.enable_admin_inline_mode?
            tr(label, desc, tokens, options)
          else
            trl(label, desc, tokens, options)
          end
        else
          Tr8nClientSdk::Config.default_language.translate(label, desc, tokens, options)
        end
      end
      
      # for admin translations
      def trla(label, desc = "", tokens = {}, options = {})
        tra(label, desc, tokens, options.merge(:skip_decorations => true))
      end
  
      ######################################################################
      ## Common methods
      ######################################################################

      def tr8n_current_user
        Tr8nClientSdk::Config.current_user
      end

      def tr8n_current_language
        Tr8nClientSdk::Config.current_language
      end

      def tr8n_default_language
        Tr8nClientSdk::Config.default_language
      end

      def tr8n_current_translator
        Tr8nClientSdk::Config.current_translator
      end
    
      def tr8n_current_user_is_admin?
        Tr8nClientSdk::Config.current_user_is_admin?
      end
    
      def tr8n_current_user_is_translator?
        Tr8nClientSdk::Config.current_user_is_translator?
      end

      def tr8n_current_user_is_manager?
        return true if Tr8nClientSdk::Config.current_user_is_admin?
        return false unless Tr8nClientSdk::Config.current_user_is_translator?
        tr8n_current_translator.manager?
      end
    
      def tr8n_current_user_is_guest?
        Tr8nClientSdk::Config.current_user_is_guest?
      end

    end
  end
end
