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
  module ActionCommonMethods
    ############################################################
    # There are three ways to call the tr method
    #
    # tr(label, desc = "", tokens = {}, options = {})
    # or
    # tr(label, tokens = {}, options = {})
    # or
    # tr(:label => label, :description => "", :tokens => {}, :options => {})
    ############################################################
    def tr(label, description = "", tokens = {}, options = {})
      return label.html_safe if label.tr8n_translated?

      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)
      params[:options][:caller] = caller

      if request
        params[:options][:url]  = request.url
        params[:options][:host] = request.env['HTTP_HOST']
      end

      if Tr8n.config.disabled?
        return Tr8n::TranslationKey.substitute_tokens(params[:label], params[:tokens], params[:options]).tr8n_translated.html_safe
      end

      # Translate individual sentences
      if params[:options][:split]
        text = params[:label]
        sentences = Tr8n::Utils.split_by_sentence(text)
        sentences.each do |sentence|
          text = text.gsub(sentence, tr8n_current_language.translate(sentence, params[:description], params[:tokens], params[:options]))
        end
        return text.tr8n_translated.html_safe
      end

      tr8n_current_language.translate(params).tr8n_translated.html_safe
    rescue Tr8n::Exception => ex
      Tr8n::Logger.error("ERROR: #{label}")
      Tr8n::Logger.error(ex.message + "\n=> " + ex.backtrace.join("\n=> "))
      label
    end

    # for translating labels
    def trl(label, description = "", tokens = {}, options = {})
      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)
      params[:options][:skip_decorations] = true
      tr(params)
    end

    # flash notice
    def trfn(label, desc = "", tokens = {}, options = {})
      flash[:trfn] = tr(Tr8n::Utils.normalize_tr_params(label, desc, tokens, options))
    end

    # flash error
    def trfe(label, desc = "", tokens = {}, options = {})
      flash[:trfe] = tr(Tr8n::Utils.normalize_tr_params(label, desc, tokens, options))
    end

    # flash warning
    def trfw(label, desc = "", tokens = {}, options = {})
      flash[:trfw] = tr(Tr8n::Utils.normalize_tr_params(label, desc, tokens, options))
    end

    ######################################################################
    ## Common methods - wrappers
    ######################################################################

    def tr8n_application
      Tr8n.session.application
    end

    def tr8n_current_user
      Tr8n.session.current_user
    end

    def tr8n_current_translator
      Tr8n.session.current_translator
    end

    def tr8n_current_language
      Tr8n.session.current_language
    end

  end
end
