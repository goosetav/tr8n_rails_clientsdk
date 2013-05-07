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
#
#-- Tr8nClientSdk::Translation Schema Information
#
# Table name: tr8n_translations
#
#  id                    INTEGER       not null, primary key
#  translation_key_id    integer       not null
#  language_id           integer       not null
#  translator_id         integer       not null
#  label                 text          not null
#  rank                  integer       default = 0
#  approved_by_id        integer(8)    
#  rules                 text          
#  synced_at             datetime      
#  created_at            datetime      not null
#  updated_at            datetime      not null
#
# Indexes
#
#  tr8n_trn_c       (created_at) 
#  tr8n_trn_tktl    (translation_key_id, translator_id, language_id) 
#  tr8n_trn_t       (translator_id) 
#
#++

class Tr8nClientSdk::Translation < ActiveRecord::Base
  self.table_name = :tr8n_translations
  attr_accessible :translation_key_id, :language_id, :translator_id, :label, :rank, :approved_by_id, :rules, :synced_at
  attr_accessible :language, :translator, :translation_key

  belongs_to :language,         :class_name => "Tr8nClientSdk::Language"
  belongs_to :translation_key,  :class_name => "Tr8nClientSdk::TranslationKey"
  belongs_to :translator,       :class_name => "Tr8nClientSdk::Translator"
  
  has_many   :translation_votes, :class_name => "Tr8nClientSdk::TranslationVote", :dependent => :destroy
  
  serialize :rules
    
  alias :key :translation_key
  alias :votes :translation_votes

  # TODO: move this to config file
  VIOLATION_INDICATOR = -10

  # populate language rules from the internal rules hash
  def rules
    super_rules = super
    return nil if super_rules == nil
    return nil unless super_rules.class.name == 'Array'
    return nil if super_rules.size == 0

    @loaded_rules ||= begin
      rulz = []
      super_rules.each do |rule|
        [rule[:rule_id]].flatten.each do |rule_id|
          language_rule = Tr8nClientSdk::LanguageRule.by_id(rule_id)
          rulz << rule.merge({:rule => language_rule}) if language_rule
        end
      end
      rulz
    end
  end

  # generates a hash of token => rule_id
  # TODO: is this still being used? 
  # Warning: same token can have multiple rules in a single translation
  def rules_hash
    return nil if rules.nil? or rules.empty? 
    
    @rules_hash ||= begin
      rulz = {}
      rules.each do |rule|
        rulz[rule[:token]] = rule[:rule_id]  
      end
      rulz
    end
  end

  # deprecated - api_hash should be used instead
  def rules_definitions
    return nil if rules.nil? or rules.empty? 
    @rules_definitions ||= begin
      rulz = {}
      rules.each do |rule|
        rulz[rule[:token].clone] = rule[:rule].to_hash  
      end
      rulz
    end
  end


  # checks if the translation is valid for the given tokens
  def matches_rules?(token_values)
    return true if rules.nil? # doesn't have any rules
    return false if rules.empty?  # had some rules that have been removed
    
    rules.each do |rule|
      token_value = token_values[rule[:token].to_sym]
      token_value = token_value.first if token_value.is_a?(Array)
      result = rule[:rule].evaluate(token_value)
      return false unless result
    end
    
    true
  end
  
  # used by the permutation generator
  def matches_rule_definitions?(new_rules_hash)
    rules_hash == new_rules_hash
  end

  def self.default_translation(translation_key, language, translator)
    trans = where("translation_key_id = ? and language_id = ? and translator_id = ? and rules is null", translation_key.id, language.id, translator.id).order("rank desc").first
    return trans if trans
    label = translation_key.default_translation if translation_key.is_a?(Tr8nClientSdk::RelationshipKey)
    new(:translation_key => translation_key, :language => language, :translator => translator, :label => label || translation_key.sanitized_label)
  end

  def blank?
    self.label.blank?    
  end

  def uniq?
    # for now, treat all translations as uniq
    return true
    
    trns = self.class.where("translation_key_id = ? and language_id = ? and label = ?", translation_key.id, language.id, label)
    trns = trns.where("id <> ?", self.id) if self.id
    trns.count == 0
  end
  
end
