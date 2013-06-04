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
  module ActionViewExtension
    extend ActiveSupport::Concern

    # Creates an instance of tr8nProxy object
    def tr8n_client_sdk_tag(opts = {})
      #TODO - add a javascript source
      ""
    end

    # translation functions
    def tr(label, desc = "", tokens = {}, options = {})
      return label if label.tr8n_translated?

      if desc.is_a?(Hash)
        options = desc
        tokens  = options[:tokens] || {}
        desc    = options[:context] || ""
      end

      options.merge!(:caller => caller)
      if request
        options.merge!(:url => request.url)
        options.merge!(:host => request.env['HTTP_HOST'])
      end

      unless Tr8n::Config.enabled?
        return Tr8n::TranslationKey.substitute_tokens(label, tokens, options).html_safe
      end

      Tr8n::Config.current_language.translate(label, desc, tokens, options)
    end

    # for translating labels
    def trl(label, desc = "", tokens = {}, options = {})
      tr(label, desc, tokens, options.merge(:skip_decorations => true))
    end

    # for admin translations
    def tra(label, desc = "", tokens = {}, options = {})
      if Tr8n::Config.enable_admin_translations?
        if Tr8n::Config.enable_admin_inline_mode?
          tr(label, desc, tokens, options)
        else
          trl(label, desc, tokens, options)
        end
      else
        Tr8n::Config.default_language.translate(label, desc, tokens, options)
      end
    end
    
    # for admin translations
    def trla(label, desc = "", tokens = {}, options = {})
      tra(label, desc, tokens, options.merge(:skip_decorations => true))
    end

    def tr8n_options_for_select(options, selected = nil, description = nil, lang = Tr8n::Config.current_language)
      options_for_select(options.tro(description), selected)
    end

    def tr8n_phrases_link_tag(search = "", phrase_type = :without, phrase_status = :any)
      return unless Tr8n::Config.enabled?
      return if Tr8n::Config.current_language.default?
      return unless Tr8n::Config.open_registration_mode? or Tr8n::Config.current_user_is_translator?
      return unless Tr8n::Config.current_translator.enable_inline_translations?

      link_to(image_tag("tr8n/translate_icn.gif", :style => "vertical-align:middle; border: 0px;", :title => search), 
             :controller => "/tr8n/phrases", :action => :index, 
             :search => search, :phrase_type => phrase_type, :phrase_status => phrase_status).html_safe
    end

    def tr8n_language_flag_tag(lang = Tr8n::Config.current_language, opts = {})
      return "" unless Tr8n::Config.enable_language_flags?
      html = image_tag(Tr8n::Config.url_for("/assets/tr8n/flags/#{lang.flag}.png"), :style => "vertical-align:middle;", :title => lang.native_name)
      html << "&nbsp;".html_safe 
      html.html_safe
    end

    def tr8n_language_name_tag(lang = Tr8n::Config.current_language, opts = {})
      show_flag = opts[:flag].nil? ? true : opts[:flag]
      name_type = opts[:name].nil? ? :full : opts[:name] # :full, :native, :english, :locale
      linked = opts[:linked].nil? ? true : opts[:linked] 

      html = "<span style='white-space: nowrap'>"
      html << tr8n_language_flag_tag(lang, opts) if show_flag
      html << "<span dir='ltr'>"

      name = case name_type
        when :native  then lang.native_name
        when :english then lang.english_name
        when :locale  then lang.locale
        else lang.full_name
      end

      if linked
        html << link_to(name.html_safe, "/tr8n/language/switch?locale=#{lang.locale}&language_action=switch_language&source_url=#{CGI.escape(opts[:source_url]||'')}")
      else    
        html << name
      end

      html << "</span></span>"
      html.html_safe
    end

    def tr8n_language_selector_tag(opts = {})
      opts[:lightbox] ||= false
      opts[:style] ||= "color:#1166bb;"
      opts[:show_arrow] ||= true
      opts[:arrow_style] ||= "font-size:8px;"
      render(:partial => '/tr8n_client_sdk/tags/language_selector', :locals => {:opts => opts})    
    end

    def tr8n_language_strip_tag(opts = {})
      opts[:flag] = opts[:flag].nil? ? false : opts[:flag]
      opts[:name] = opts[:name].nil? ? :native : opts[:name] 
      opts[:linked] = opts[:linked].nil? ? true : opts[:linked] 
      opts[:javascript] = opts[:javascript].nil? ? false : opts[:javascript] 

      render(:partial => '/tr8n_client_sdk/tags/language_strip', :locals => {:opts => opts})    
    end

    def tr8n_language_table_tag(opts = {})
      opts[:cols] = opts[:cols].nil? ? 4 : opts[:cols]
      opts[:col_size] = opts[:col_size].nil? ? "300px" : opts[:col_size]
      render(:partial => '/tr8n_client_sdk/tags/language_table', :locals => {:opts => opts.merge(:name => :english)})    
    end

    def tr8n_flashes_tag(opts = {})
      render(:partial => '/tr8n_client_sdk/tags/flashes', :locals => {:opts => opts})    
    end

    def tr8n_scripts_tag(opts = {})
      render(:partial => '/tr8n_client_sdk/tags/scripts', :locals => {:opts => opts})    
    end

    def tr8n_select_month(date, options = {}, html_options = {})
      month_names = options[:use_short_month] ? Tr8n::Config.default_abbr_month_names : Tr8n::Config.default_month_names
      select_month(date, options.merge(
        :use_month_names => month_names.collect{|month_name| Tr8n::Language.translate(month_name, options[:description] || "Month name")} 
      ), html_options)
    end

    def tr8n_with_options_tag(opts, &block)
      if Tr8n::Config.disabled?
        return capture(&block) if block_given?
        return ""
      end

      Thread.current[:tr8n_block_options] ||= []   
      Thread.current[:tr8n_block_options].push(opts)

      component = Tr8n::Config.current_component_from_block_options
      if component
        source = Tr8n::Config.current_source_from_block_options
        unless source.nil?
          Tr8n::ComponentSource.find_or_create(component, source)
        end
      end

      if Tr8n::Config.current_user_is_authorized_to_view_component?(component)
        selected_language = Tr8n::Config.current_language
        
        unless Tr8n::Config.current_user_is_authorized_to_view_language?(component, selected_language)
          Tr8n::Config.set_language(Tr8n::Config.default_language)
        end

        if block_given?
          ret = capture(&block) 
        end

        Tr8n::Config.set_language(selected_language)
      else
        ret = ""
      end

      Thread.current[:tr8n_block_options].pop
      ret
    end

    def tr8n_content_for_locales_tag(opts = {}, &block)
      locale = Tr8n::Config.current_language.locale

      if opts[:only] 
         return unless opts[:only].include?(locale)
      end

      if opts[:except]
        return if opts[:except].include?(locale)
      end

      if block_given?
        ret = capture(&block) 
      end
      ret
    end

    def tr8n_content_for_countries_tag(opts = {}, &block)
      country = Tr8n::Config.country_from_ip(tr8n_request_remote_ip)
      
      if opts[:only] 
         return unless opts[:only].include?(country)
      end

      if opts[:except]
        return if opts[:except].include?(country)
      end

      if block_given?
        ret = capture(&block) 
      end
      ret
    end

    ######################################################################
    ## Language Direction Support
    ######################################################################

    def tr8n_style_attribute_tag(attr_name = 'float', default = 'right', lang = Tr8n::Config.current_language)
      "#{attr_name}:#{lang.align(default)}".html_safe
    end

    def tr8n_style_directional_attribute_tag(attr_name = 'padding', default = 'right', value = '5px', lang = Tr8n::Config.current_language)
      "#{attr_name}-#{lang.align(default)}:#{value}".html_safe
    end

    def tr8n_dir_attribute_tag(lang = Tr8n::Config.current_language)
      "dir='#{lang.dir}'".html_safe
    end

    ######################################################################
    ## Common methods
    ######################################################################

    def tr8n_request_remote_ip
      @remote_ip ||= if request.env['HTTP_X_FORWARDED_FOR']
        request.env['HTTP_X_FORWARDED_FOR'].split(',').first
      else
        request.remote_ip
      end
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
  
    def tr8n_current_user_is_admin?
      Tr8n::Config.current_user_is_admin?
    end
  
    def tr8n_current_user_is_translator?
      Tr8n::Config.current_user_is_translator?
    end

    def tr8n_current_user_is_manager?
      return true if Tr8n::Config.current_user_is_admin?
      return false unless Tr8n::Config.current_user_is_translator?
      tr8n_current_translator.manager?
    end
  
    def tr8n_current_user_is_guest?
      Tr8n::Config.current_user_is_guest?
    end

    def tr8n_when_string_tag(time, opts = {})
      elapsed_seconds = Time.now - time
      if elapsed_seconds < 0
        tr('In the future, Marty!', 'Time reference')
      elsif elapsed_seconds < 2.minutes
        tr('a moment ago', 'Time reference')
      elsif elapsed_seconds < 55.minutes
        elapsed_minutes = (elapsed_seconds / 1.minute).to_i
        tr("{minutes||minute} ago", 'Time reference', :minutes => elapsed_minutes)
      elsif elapsed_seconds < 1.75.hours
        tr("about an hour ago", 'Time reference')
      elsif elapsed_seconds < 12.hours
        elapsed_hours = (elapsed_seconds / 1.hour).to_i
        tr("{hours||hour} ago", 'Time reference', :hours => elapsed_hours)
      elsif time.today_in_time_zone?
        display_time(time, :time_am_pm)
      elsif time.yesterday_in_time_zone?
        tr("Yesterday at {time}", 'Time reference', :time => time.tr(:time_am_pm).gsub('/ ', '/').sub(/^[0:]*/,""))
      elsif elapsed_seconds < 5.days
        time.tr(:day_time).gsub('/ ', '/').sub(/^[0:]*/,"")
      elsif time.same_year_in_time_zone?
        time.tr(:monthname_abbr_time).gsub('/ ', '/').sub(/^[0:]*/,"")
      else
        time.tr(:monthname_abbr_year_time).gsub('/ ', '/').sub(/^[0:]*/,"")
      end
    end
    
  end
end
