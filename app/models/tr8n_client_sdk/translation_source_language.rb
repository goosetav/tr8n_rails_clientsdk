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
#-- Tr8nClientSdk::TranslationSourceLanguage Schema Information
#
# Table name: tr8n_translation_source_languages
#
#  id                       INTEGER     not null, primary key
#  language_id              integer     
#  translation_source_id    integer     
#  created_at               datetime    not null
#  updated_at               datetime    not null
#
# Indexes
#
#  tr8n_tsl_lt    (language_id, translation_source_id) 
#
#++

class Tr8nClientSdk::TranslationSourceLanguage < ActiveRecord::Base
  self.table_name = :tr8n_translation_source_languages
  attr_accessible :language_id, :translation_source_id
  attr_accessible :translation_source, :language

  belongs_to  :translation_source,  :class_name => "Tr8nClientSdk::TranslationSource"
  belongs_to  :language,  :class_name => "Tr8nClientSdk::Language"
  
  def self.find_or_create(translation_source, language = Tr8nClientSdk::Config.current_language)
    source_lang = where("translation_source_id = ? and language_id = ?", translation_source.id, language.id).first
    source_lang ||= create(:translation_source => translation_source, :language => language)
  end  
  
  def self.touch(translation_source, language = Tr8nClientSdk::Config.current_language)
    find_or_create(translation_source, language).touch
  end
  
end
