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

class Tr8n::Rules::Gender < Tr8n::Rules::Base

  attributes :operator, :value

  def self.key
    "gender" 
  end

  def self.suffixes
    Tr8n::Config.rules_engine[:gender_rule][:token_suffixes]
  end

  def self.gender_method_name
    Tr8n::Config.rules_engine[:gender_rule][:object_method]
  end

  def self.token_value(token)
    if token.is_a?(Hash)
      return nil unless token[:object]
      return token[:object][gender_method_name]
    end

    return nil unless token and token.respond_to?(gender_method_name)
    token.send(gender_method_name)
  end

  def self.gender_object_value_for(type)
    Tr8n::Config.rules_engine[:gender_rule][:method_values][type]
  end

  def gender_object_value_for(type)
    self.class.gender_object_value_for(type)
  end
  
  # FORM: [object, male, female, unknown]
  # {user | registered on}
  # {user | he, she}
  # {user | he, she, he/she}
  def self.transform(*args)
    unless [2, 3, 4].include?(args.size)
      raise Tr8n::Exception.new("Invalid transform arguments for gender token")
    end
    
    return args[1] if args.size == 2
    
    object = args[0]
    object_value = gender_token_value(object)
    
    unless object_value
      raise Tr8n::Exception.new("Token #{object.class.name} does not respond to #{gender_method_name}")
    end
    
    if (object_value == gender_object_value_for("male"))
      return args[1]
    elsif (object_value == gender_object_value_for("female"))
      return args[2]
    end

    return args[3] if args.size == 4
    
    "#{args[1]}/#{args[2]}"  
  end
  
  def evaluate(token)
    token_value = token_value(token)
    return false unless token_value
    
    if operator == "is"
      return true if token_value == gender_object_value_for(value)
    end

    if operator == "is_not"
      return true if token_value != gender_object_value_for(value)
    end
    
    false    
  end
  
end