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
#-- Tr8nClientSdk::TranslationDomain Schema Information
#
# Table name: tr8n_translation_domains
#
#  id              INTEGER         not null, primary key
#  name            varchar(255)    
#  description     varchar(255)    
#  source_count    integer         default = 0
#  created_at      datetime        not null
#  updated_at      datetime        not null
#
# Indexes
#
#  tr8n_td_n    (name) UNIQUE
#
#++

require "socket"

class Tr8nClientSdk::TranslationDomain < ActiveRecord::Base
  self.table_name = :tr8n_translation_domains
  attr_accessible :name, :description, :source_count

  has_many    :translation_sources,       :class_name => "Tr8nClientSdk::TranslationSource",     :dependent => :destroy
  has_many    :translation_key_sources,   :class_name => "Tr8nClientSdk::TranslationKeySource",  :through => :translation_sources
  has_many    :translation_keys,          :class_name => "Tr8nClientSdk::TranslationKey",        :through => :translation_key_sources
  
  alias :sources      :translation_sources
  alias :key_sources  :translation_key_sources
  alias :keys         :translation_keys
  
  def self.cache_key(domain_name)
    "translation_domain_[#{domain_name}]"
  end

  def cache_key
    self.class.cache_key(name)
  end

  def self.find_or_create(source)
    # begin
    #   domain_name = URI.parse(source || 'localhost').host || 'localhost'
    # rescue Exception => ex
    #   domain_name = source
    # end

    domain_name = Socket::gethostname
    Tr8nClientSdk::Cache.fetch(cache_key(domain_name)) do 
      find_by_name(domain_name) || create(:name => domain_name)
    end  
  end
    
end
