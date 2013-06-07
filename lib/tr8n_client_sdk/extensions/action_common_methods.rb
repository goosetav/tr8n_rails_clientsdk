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
  module ActionCommonMethods
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

      unless Tr8n::Config.enabled?
        return Tr8n::TranslationKey.substitute_tokens(label, tokens, options)
      end

      Tr8n::Config.current_language.translate(label, desc, tokens, options)
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

    # flash warning
    def trfw(label, desc = "", tokens = {}, options = {})
      flash[:trfw] = tr(label, desc, tokens, options)
    end

    ######################################################################
    ## Common methods - wrappers
    ######################################################################

    def tr8n_application
      Tr8n::Config.application
    end

    def tr8n_current_user
      Tr8n::Config.current_user
    end

    def tr8n_current_language
      Tr8n::Config.current_language
    end

    def tr8n_default_language
      Tr8n::Config.default_language
    end

    def tr8n_current_translator
      Tr8n::Config.current_translator
    end

    def tr8n_current_user_is_guest?
      Tr8n::Config.current_user_is_guest?
    end

    def tr8n_current_user_is_translator?
      Tr8n::Config.current_user_is_translator?
    end

  end
end
