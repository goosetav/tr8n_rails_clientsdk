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
#-- Tr8nClientSdk::ComponentSource Schema Information
#
# Table name: tr8n_component_sources
#
#  id                       INTEGER     not null, primary key
#  component_id             integer     
#  translation_source_id    integer     
#  created_at               datetime    not null
#  updated_at               datetime    not null
#
# Indexes
#
#  tr8n_comp_src_id     (translation_source_id) 
#  tr8n_comp_comp_id    (component_id) 
#
#++

class Tr8nClientSdk::ComponentSource < ActiveRecord::Base
  self.table_name = :tr8n_component_sources
  attr_accessible :component, :translation_source

  belongs_to :component, :class_name => 'Tr8nClientSdk::Component'
  belongs_to :translation_source, :class_name => 'Tr8nClientSdk::TranslationSource'

  has_many :translation_key_sources, :class_name => 'Tr8nClientSdk::TranslationKeySource', :through => :translation_source
  has_many :translation_keys, :class_name => 'Tr8nClientSdk::TranslationKey', :through => :translation_key_sources

  def self.find_or_create(component, source)
    where("component_id = ? and translation_source_id = ?", component.id, source.id).first || create(:component => component, :translation_source => source)
  end

end
