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

class Tr8n::Rules::List < Tr8n::Rules::Base
  attributes :value

  def self.key
    "list" 
  end

  def self.suffixes
    Tr8n::Config.rules_engine[:list_rule][:token_suffixes]
  end
  
  def self.list_method_name
    Tr8n::Config.rules_engine[:list_rule][:object_method]
  end

  def self.token_value(token)
    return nil unless token and token.respond_to?(list_method_name)
    token.send(list_method_name)
  end

  # params: [object, one element, at least two elements]
  # {user_list | one element, at least two elements}
  def self.transform(*args)
    unless args.size == 3
      raise Tr8n::Exception.new("Invalid transform arguments")
    end
    
    object = args[0]
    list_size = token_value(object)

    unless list_size
      raise Tr8n::Exception.new("Token #{object.class.name} does not respond to #{list_method_name}")
    end
    
    list_size = list_size.to_i
    
    return args[1] if list_size == 1
    
    args[2]
  end  
  
  def evaluate(token)
    return false unless token.kind_of?(Enumerable)
    
    list_size = token_value(token)
    return false if list_size == nil
    list_size = list_size.to_i

    case value
      when "one_element" then
        return true if list_size == 1
      when "at_least_two_elements" then
        return true if list_size >= 2
    end
    
    false
  end
  
end