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

class Tr8n::Rules::Date < Tr8n::Rules::Base
  attributes :value

  def self.key
    "date" 
  end

  def self.suffixes
    Tr8n::Config.rules_engine[:date_rule][:token_suffixes]
  end

  def self.default_rules_for(language = Tr8n::Config.current_language)
    Tr8n::Config.default_date_rules(language.locale)
  end

  def self.date_method_name
    Tr8n::Config.rules_engine[:date_rule][:object_method]
  end
  
  def self.token_value(token)
    return nil unless token and token.respond_to?(date_method_name)
    token.send(date_method_name)
  end

  # params: [object, past, present, future]
  # form: {date | did, is doing, will do}
  def self.transform(*args)
    if args.size != 4
      raise Tr8n::Exception.new("Invalid transform arguments")
    end
    
    object = args[0]
    object_date = token_value(object)

    unless object_date
      raise Tr8n::Exception.new("Token #{object.class.name} does not respond to #{date_method_name}")
    end

    current_date = Date.today
    
    if object_date < current_date
      return args[1]
    elsif object_date > current_date
      return args[3]
    end
    
    args[2]
  end  

  def evaluate(token)
    return false unless token.is_a?(Date) or token.is_a?(Time)
    
    token_value = token_value(token)
    return false unless token_value
    
    current_date = Date.today
    
    case value
      when "past" then
          return true if token_value < current_date
      when "present" then
          return true if token_value == current_date
      when "future" then
          return true if token_value > current_date
    end

    false    
  end
  
end