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

class Tr8nClientSdk::Translator < ActiveRecord::Base
  self.table_name = :tr8n_translators
  attr_accessible :user_id, :inline_mode, :blocked, :reported, :fallback_language_id, :rank, :name, :gender, :email, :password, :mugshot, :link, :locale, :level, :manager, :last_ip, :country_code, :remote_id, :voting_power
  attr_accessible :user

  belongs_to :user, :class_name => Tr8nClientSdk::Config.user_class_name, :foreign_key => :user_id
  
  has_many  :translator_logs,               :class_name => "Tr8nClientSdk::TranslatorLog",             :dependent => :destroy, :order => "created_at desc"
  has_many  :translator_following,          :class_name => "Tr8nClientSdk::TranslatorFollowing",       :dependent => :destroy, :order => "created_at desc"
  has_many  :translator_metrics,            :class_name => "Tr8nClientSdk::TranslatorMetric",          :dependent => :destroy
  has_many  :translations,                  :class_name => "Tr8nClientSdk::Translation",               :dependent => :destroy
  has_many  :translation_votes,             :class_name => "Tr8nClientSdk::TranslationVote",           :dependent => :destroy
  has_many  :translation_key_locks,         :class_name => "Tr8nClientSdk::TranslationKeyLock",        :dependent => :destroy
  has_many  :language_users,                :class_name => "Tr8nClientSdk::LanguageUser",              :dependent => :destroy
  has_many  :language_forum_topics,         :class_name => "Tr8nClientSdk::LanguageForumTopic",        :dependent => :destroy
  has_many  :language_forum_messages,       :class_name => "Tr8nClientSdk::LanguageForumMessage",      :dependent => :destroy
  has_many  :languages,                     :class_name => "Tr8nClientSdk::Language",                  :through => :language_users

  belongs_to :fallback_language,            :class_name => 'Tr8nClientSdk::Language',                  :foreign_key => :fallback_language_id
    
  def self.cache_key(user_id)
    "translator_[#{user_id}]"
  end

  def cache_key
    self.class.cache_key(user_id)
  end

  def self.for(user)
    return nil unless user and user.id 
    return nil if Tr8nClientSdk::Config.guest_user?(user)
    translator = Tr8nClientSdk::Cache.fetch(cache_key(user.id)) do 
      find_by_user_id(user.id)
    end
  end
  
  def self.find_or_create(user)
    return nil unless user and user.id 

    trn = where(:user_id => user.id).first
    trn = create(:user => user) unless trn
    trn
  end

  def self.register(user = Tr8nClientSdk::Config.current_user)
    return nil unless user and user.id 
    return nil if Tr8nClientSdk::Config.guest_user?(user)

    translator = Tr8nClientSdk::Translator.find_or_create(user)
    return nil unless translator

    # update all language user entries to add a translator id
    Tr8nClientSdk::LanguageUser.where(:user_id => user.id).each do |lu|
      lu.update_attributes(:translator => translator)
    end
    translator
  end
  
  def rank
    total_metric.rank
  end
      
  def voting_power
    super || 1
  end

  def enable_inline_translations?
    inline_mode == true
  end
  
  # all admins are always manager for all languages
  def manager?
    return true if Tr8nClientSdk::Config.admin_user?(user)
    return true if level >= Tr8nClientSdk::Config.manager_level
    false
  end

  def admin?
    # stand alone translators are always admins
    return false unless user
    Tr8nClientSdk::Config.admin_user?(user)
  end  

  def guest?
    return true unless user
    Tr8nClientSdk::Config.guest_user?(user)
  end  

  def level
    return Tr8nClientSdk::Config.admin_level if admin?
    return 0 if super.nil?
    super
  end

  def to_s
    name
  end

end
