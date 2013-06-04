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

class Tr8n::Rules::Base < Tr8n::Base
  attributes :id, :locale, :definition

  def self.rule_class(type)
    # TODO: move it to the config for dynamic load
    {
      'number' => Tr8n::Rules::Number,
      'gender' => Tr8n::Rules::Gender,
      'date' => Tr8n::Rules::Date,
      'list' => Tr8n::Rules::List
    }[type]
  end

  def self.cache_key(rule_id)
    "language_rule_[#{rule_id}]"
  end

  def cache_key
    self.class.cache_key(self.id)
  end
  
  def self.suffixes
    []  
  end
  
  def self.dependant?(token)
    token.dependency == dependency or suffixes.include?(token.suffix)
  end

  def self.key
    raise Tr8n::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def self.token_value(token)
    token.to_s
  end

  def token_value(token)
    self.class.token_value(token)
  end

  def self.sanitize_values(values)
    return [] unless values
    values.split(",").collect{|val| val.strip} 
  end
  
  def sanitize_values(values)
    self.class.sanitize_values(values)
  end

  def evaluate(token_value)
    raise Tr8n::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def self.transformable?
    true
  end

end