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

    def tr8n_options_for_select(options, selected = nil, description = nil, lang = Tr8n.config.current_language)
      options_for_select(options.tro(description), selected)
    end

    def tr8n_phrases_link_tag(search = "", phrase_type = :without, phrase_status = :any)
      return unless Tr8n.config.enabled?
      return if Tr8n.config.current_language.default?
      return unless Tr8n.config.current_translator.inline?

      link_to(image_tag(Tr8n.config.url_for("/assets/tr8n/translate_icn.gif"), :style => "vertical-align:middle; border: 0px;", :title => search),
                        Tr8n.config.url_for("/tr8n/app/phrases/index?search=#{search}")).html_safe
    end

    def tr8n_language_flag_tag(lang = Tr8n.config.current_language, opts = {})
      return "" unless Tr8n.config.application.feature_enabled?(:language_flags)
      html = image_tag(lang.flag_url, :style => "vertical-align:middle;", :title => lang.native_name)
      html << "&nbsp;".html_safe 
      html.html_safe
    end

    def tr8n_language_name_tag(lang = Tr8n.config.current_language, opts = {})
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

#      if linked
#        # Todo: use language selector
##        html << link_to(name.html_safe, "/tr8n/language/switch?locale=#{lang.locale}&language_action=switch_language&source_url=#{CGI.escape(opts[:source_url]||'')}")
#      else
        html << name
      #end

      html << "</span></span>"
      html.html_safe
    end

    def tr8n_language_strip_tag(opts = {})
      opts[:flag] = opts[:flag].nil? ? false : opts[:flag]
      opts[:name] = opts[:name].nil? ? :native : opts[:name] 
      opts[:linked] = opts[:linked].nil? ? true : opts[:linked] 
      opts[:javascript] = opts[:javascript].nil? ? false : opts[:javascript] 

      render(:partial => '/tr8n_client_sdk/tags/language_strip', :locals => {:opts => opts})    
    end

    def tr8n_flashes_tag(opts = {})
      render(:partial => '/tr8n_client_sdk/tags/flashes', :locals => {:opts => opts})    
    end

    def tr8n_scripts_tag(opts = {})
      render(:partial => '/tr8n_client_sdk/tags/scripts', :locals => {:opts => opts})    
    end

    def tr8n_select_month(date, options = {}, html_options = {})
      month_names = options[:use_short_month] ? Tr8n.config.default_abbr_month_names : Tr8n.config.default_month_names
      select_month(date, options.merge(
        :use_month_names => month_names.collect{|month_name| Tr8n::Language.translate(month_name, options[:description] || "Month name")} 
      ), html_options)
    end

    def tr8n_with_options_tag(opts, &block)
      if Tr8n.config.disabled?
        return capture(&block) if block_given?
        return ""
      end

      Thread.current[:block_options] ||= []
      Thread.current[:block_options].push(opts)

      #component = Tr8n.config.current_component_from_block_options
      #if component
      #  source = Tr8n.config.current_source_from_block_options
      #  unless source.nil?
      #    Tr8n::ComponentSource.find_or_create(component, source)
      #  end
      #end
      #
      #if Tr8n.config.current_user_is_authorized_to_view_component?(component)
      #  selected_language = Tr8n.config.current_language
      #
      #  unless Tr8n.config.current_user_is_authorized_to_view_language?(component, selected_language)
      #    Tr8n.config.set_language(Tr8n.config.default_language)
      #  end
      #
      #  if block_given?
      #    ret = capture(&block)
      #  end
      #
      #  Tr8n.config.current_language = selected_language
      #else
      #  ret = ""
      #end

      if block_given?
        ret = capture(&block)
      end

      Thread.current[:block_options].pop
      ret
    end

    def tr8n_content_for_locales_tag(opts = {}, &block)
      locale = Tr8n.config.current_language.locale

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
      country = Tr8n.config.country_from_ip(tr8n_request_remote_ip)
      
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
    
    ######################################################################
    ## Language Direction Support
    ######################################################################

    def tr8n_style_attribute_tag(attr_name = 'float', default = 'right', lang = Tr8n.config.current_language)
      "#{attr_name}:#{lang.align(default)}".html_safe
    end

    def tr8n_style_directional_attribute_tag(attr_name = 'padding', default = 'right', value = '5px', lang = Tr8n.config.current_language)
      "#{attr_name}-#{lang.align(default)}:#{value}".html_safe
    end

    def tr8n_dir_attribute_tag(lang = Tr8n.config.current_language)
      "dir='#{lang.dir}'".html_safe
    end

  end
end
