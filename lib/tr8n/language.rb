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

class Tr8n::Language < Tr8n::Base
  attributes :locale, :name, :english_name, :native_name, :right_to_left, :enabled, :google_key, :facebook_key, :myheritage_key
  attributes :context_rules, :context_rules_by_type, :context_rules_by_type_and_keyword, :language_cases

  def self.by_locale(locale)
    Tr8n::Config.application.language_by_locale(locale)
  end

  def initialize(attrs = {})
    super

    if attrs['context_rules']
      self.context_rules = []
      self.attributes[:context_rules_by_type] = {}
      self.attributes[:context_rules_by_type_and_keyword] = {}

      attrs['context_rules'].each do |rule_class|
        klass = Tr8n::Rules::Base.rule_class(rule_class['type'])

        self.attributes[:context_rules_by_type][rule_class['type']] ||= []
        rule_class['rules'].each do |rule|
          context_rule = klass.new(rule)
          self.context_rules << context_rule
          self.attributes[:context_rules_by_type][rule_class['type']] << context_rule
          self.attributes[:context_rules_by_type_and_keyword]["#{rule_class['type']}_#{rule['keyword']}"] = context_rule
        end
      end
    end

    if attrs['language_cases']
      self.language_cases = attrs['language_cases'].collect{ |lcase| Tr8n::LanguageCase.new(lcase) }
    end
  end

  def context_rules_by_type(type)
    self.attributes[:context_rules_by_type] ||= {}
    self.attributes[:context_rules_by_type][type]
  end

  def context_rules_by_type_and_keyword(type, keyword)
    self.attributes[:context_rules_by_type_and_keyword] ||= {}
    self.attributes[:context_rules_by_type_and_keyword]["#{type}_#{keyword}"]
  end

  def current?
    self.locale == Tr8n::Config.current_language.locale
  end
  
  def default?
    self.locale == Tr8n::Config.default_locale
  end
  
  def flag
    locale
  end
  
  def rules?
    not rules.empty?
  end
  
  def gender_rules?
    return false unless rules?
    
    rules.each do |rule|
      return true if rule.class.dependency == 'gender'
    end
    false
  end

  def cases?
    not cases.empty?
  end

  def case_keyword_maps
    @case_keyword_maps ||= begin
      hash = {} 
      cases.each do |lcase| 
        hash[lcase.keyword] = lcase
      end
      hash
    end
  end
  
  def case_for(case_keyword)
    case_keyword_maps[case_keyword]
  end
  
  def valid_case?(case_keyword)
    case_for(case_keyword) != nil
  end
  
  def full_name
    return english_name if english_name == native_name
    "#{english_name} - #{native_name}"
  end

  def dir
    right_to_left? ? "rtl" : "ltr"
  end
  
  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end
  
  # def self.enabled_languages
  #   Tr8n::Cache.fetch(enabled_languages_cache_key) do 
  #     get("language/enabled")
  #   end
  # end

  # def self.featured_languages
  #   Tr8n::Cache.fetch(featured_languages_cache_key) do 
  #     get("language/featured")
  #   end
  # end

  def self.translate(label, desc = "", tokens = {}, options = {})
    Tr8n::Config.current_language.translate(label, desc, tokens, options)
  end

  def translate(label, desc = "", tokens = {}, options = {})
    raise Tr8n::Exception.new("The label #{label} is being translated twice") if label.tr8n_translated?

    unless Tr8n::Config.enabled?
      return Tr8n::TranslationKey.substitute_tokens(label, tokens, options, self).tr8n_translated.html_safe
    end

    translation_key = Tr8n::TranslationKey.fetch_or_register(label, desc, options)
    translation_key.translate(self, tokens.merge(:viewing_user => Tr8n::Config.current_user), options).tr8n_translated.html_safe
  end
  alias :tr :translate

  def trl(label, desc = "", tokens = {}, options = {})
    tr(label, desc, tokens, options.merge(:skip_decorations => true))
  end

  def default_rule
    @default_rule ||= Tr8n::Config.language_rule_classes.first.new(:language => self, :definition => {})
  end
  
  def rule_classes  
    @rule_classes ||= rules.collect{|r| r.class}.uniq
  end

  def rule_class_names  
    @rule_class_names ||= rule_classes.collect{|r| r.name}
  end

  def dependencies  
    @dependencies ||= rule_classes.collect{|r| r.dependency}.uniq
  end

  def default_rules_for(dependency)
    rules.select{|r| r.class.dependency == dependency}
  end

  def has_gender_rules?
    dependencies.include?("gender")
  end
  
  def threshold
    super || Tr8n::Config.translation_threshold
  end
end
