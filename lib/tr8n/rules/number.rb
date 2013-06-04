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

class Tr8n::Rules::Number < Tr8n::Rules::Base

  attributes :multipart, :part1, :value1, :part2, :value2, :operator

  def self.key
    "number" 
  end

  def self.suffixes
    Tr8n::Config.rules_engine[:numeric_rule][:token_suffixes]
  end

  def self.number_method_name
    Tr8n::Config.rules_engine[:numeric_rule][:object_method]
  end

  def self.token_value(token)
    if token.is_a?(Hash)
      return nil unless token[:object]
      return token[:object][number_method_name]
    end

    return nil unless token and token.respond_to?(number_method_name)
    token.send(number_method_name)
  end

  # FORM: [object, singular, plural]
  # {count | message}
  # {count | person, people}
  def self.transform(*args)
    unless [2, 3].include?(args.size)
      raise Tr8n::Exception.new("Invalid transform arguments for number token")
    end
    
    object = args[0]
    object_value = token_value(object)
    unless object_value
      raise Tr8n::Exception.new("Token #{object.class.name} does not respond to #{number_method_name}")
    end
    
    if object_value == 1
      return args[1]
    elsif args.size == 2
      return args[1].pluralize
    end
    
    args[2]
  end
  
  def evaluate_rule_fragment(token_value, name, values)
    if name == :is
      return true if values.include?(token_value)
      return false
    end
    
    if name == :is_not
      return true unless values.include?(token_value)
      return false
    end

    if name == :ends_in
      values.each do |value|
        return true if token_value.to_s =~ /#{value.to_s}$/  
      end
      return false
    end

    if name == :does_not_end_in
      values.each do |value|
        return false if token_value.to_s =~ /#{value.to_s}$/  
      end
      return true
    end

    if name == :starts_with
      values.each do |value|
        return true if token_value.to_s =~ /^#{value.to_s}/  
      end
      return false
    end

    if name == :does_not_start_with
      values.each do |value|
        return false if token_value.to_s =~ /^#{value.to_s}/  
      end
      return true
    end
    
    false
  end

  def evaluate(token)
    value = token_value(token)  
    return false unless value
    
    result1 = evaluate_rule_fragment(value.to_s, part1.to_sym, sanitize_values(value1))
    return result1 unless multipart?
    
    result2 = evaluate_rule_fragment(value.to_s, part2.to_sym, sanitize_values(value2))
    return (result1 or result2) if operator == "or"
    return (result1 and result2)
    
    false
  end
    
end