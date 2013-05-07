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
#-- Tr8nClientSdk::TranslationKeySource Schema Information
#
# Table name: tr8n_translation_key_sources
#
#  id                       INTEGER     not null, primary key
#  translation_key_id       integer     not null
#  translation_source_id    integer     not null
#  details                  text        
#  created_at               datetime    not null
#  updated_at               datetime    not null
#
# Indexes
#
#  tr8n_tks_ts    (translation_source_id) 
#  tr8n_tks_tk    (translation_key_id) 
#
#++

class Tr8nClientSdk::TranslationKeySource < ActiveRecord::Base
  self.table_name =  :tr8n_translation_key_sources  
  attr_accessible :translation_key_id, :translation_source_id, :details
  attr_accessible :translation_source, :translation_key

  after_destroy   :clear_cache

  belongs_to :translation_source, :class_name => "Tr8nClientSdk::TranslationSource"
  belongs_to :translation_key,    :class_name => "Tr8nClientSdk::TranslationKey"

  alias :source :translation_source
  alias :key :translation_key

  serialize :details

  def self.cache_key(tkey, source)
    "key_source_[#{tkey}]_[#{source}]"
  end

  def cache_key
    self.class.cache_key(translation_key.key, translation_source.source)
  end

  def self.find_or_create(translation_key, translation_source)
    Tr8nClientSdk::Cache.fetch(cache_key(translation_key.key, translation_source.source)) do 
      tks = where("translation_key_id = ? and translation_source_id = ?", translation_key.id, translation_source.id).first
      tks ||= begin
        translation_source.touch
        create(:translation_key => translation_key, :translation_source => translation_source)
      end
    end  
  end
  
  def update_details!(options)
    return unless options[:caller_key]
    
    self.details ||= {}
    return if details[options[:caller_key]]
    
    details[options[:caller_key]] = options[:caller]
    save
  end
  
  def clear_cache
    Tr8nClientSdk::Cache.delete(cache_key)
  end
  
end
