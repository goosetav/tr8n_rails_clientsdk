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
#-- Tr8nClientSdk::ComponentLanguage Schema Information
#
# Table name: tr8n_component_languages
#
#  id              INTEGER         not null, primary key
#  component_id    integer         
#  language_id     integer         
#  state           varchar(255)    
#  created_at      datetime        not null
#  updated_at      datetime        not null
#
# Indexes
#
#  tr8n_comp_lang_lang_id    (language_id) 
#  tr8n_comp_lang_comp_id    (component_id) 
#
#++

class Tr8nClientSdk::ComponentLanguage < ActiveRecord::Base
  self.table_name = :tr8n_component_languages
  attr_accessible :component, :language

  belongs_to :component, :class_name => 'Tr8nClientSdk::Component'
  belongs_to :language, :class_name => 'Tr8nClientSdk::Language'

  def self.find_or_create(component, language)
    where("component_id = ? and language_id = ?", component.id, language.id).first || create(:component => component, :language => language) 
  end

  def restricted?
    not live?
  end

  def live?
    state == "live"
  end

end
