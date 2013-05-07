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

class Tr8nClientSdk::LanguageRule < ActiveRecord::Base
  self.table_name = :tr8n_language_rules
  attr_accessible :language_id, :translator_id, :definition
  attr_accessible :language, :translator

  belongs_to :language, :class_name => "Tr8nClientSdk::Language"   
  belongs_to :translator, :class_name => "Tr8nClientSdk::Translator"   
  
  serialize :definition

  def self.cache_key(rule_id)
    "language_rule_[#{rule_id}]"
  end

  def cache_key
    self.class.cache_key(self.id)
  end

  def definition
    @indifferent_def ||= HashWithIndifferentAccess.new(super)
  end

  def self.by_id(rule_id)
    Tr8nClientSdk::Cache.fetch(cache_key(rule_id)) do 
      find_by_id(rule_id)
    end
  end
  
  def self.for(language)
    self.where("language_id = ?", language.id).all
  end

  def self.suffixes
    []  
  end
  
  def self.dependant?(token)
    token.dependency == dependency or suffixes.include?(token.suffix)
  end

  def self.keyword
    dependency
  end

  # TDOD: switch to using keyword
  def self.dependency
    raise Tr8nClientSdk::Exception.new("This method must be implemented in the extending rule") 
  end
  
  # TDOD: switch to using keyword
  def self.dependency_label
    dependency
  end

  def self.sanitize_values(values)
    return [] unless values
    values.split(",").collect{|val| val.strip} 
  end
  
  def self.humanize_values(values)
    sanitize_values(values).join(", ")
  end

  def evaluate(token_value)
    raise Tr8nClientSdk::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def description
    raise Tr8nClientSdk::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def token_description
    raise Tr8nClientSdk::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def self.transformable?
    true
  end

end
