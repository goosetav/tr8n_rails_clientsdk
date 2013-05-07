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

class Tr8nClientSdk::LanguageCaseValueMap < ActiveRecord::Base
  self.table_name = :tr8n_language_case_value_maps
  attr_accessible :keyword, :language_id, :translator_id, :map, :reported
  attr_accessible :language, :translator

  belongs_to :language, :class_name => "Tr8nClientSdk::Language"   
  belongs_to :translator, :class_name => "Tr8nClientSdk::Translator"   
  
  serialize :map
  
  def self.cache_key(locale, keyword)
    "language_case_value_map_[#{locale}]_[#{keyword}]"
  end

  def cache_key
    self.class.cache_key(language.locale, keyword)
  end

  def self.by_language_and_keyword(language, keyword)
    Tr8nClientSdk::Cache.fetch(cache_key(language.locale, keyword)) do 
      find_by_language_id_and_keyword_and_reported(language.id, keyword, false)
    end
  end
  
  # add a better way to determine the gender dependency
  def gender_based?
    return false unless map
    map.each do |key, value|
      return true if value.is_a?(Hash) 
    end
    false
  end
  
  def value_for(object, case_key)
    return unless map
    
    # male female definition
    if map[case_key].is_a?(Hash)
      object_gender = Tr8nClientSdk::GenderRule.gender_token_value(object)
      if object_gender == Tr8nClientSdk::GenderRule.gender_object_value_for("female")
        return map[case_key]['female']
      end
      return map[case_key]['male']
    end
    
    map[case_key] 
  end

  def implied_value_for(case_key)
    return unless map
    return gender_value_for(case_key, "male") if map[case_key].is_a?(Hash)   
    map[case_key]
  end
  
  def gender_value_for(case_key, gender)
    return unless map
    return map[case_key] unless map[case_key].is_a?(Hash)
    map[case_key][gender]
  end
  
 
end
