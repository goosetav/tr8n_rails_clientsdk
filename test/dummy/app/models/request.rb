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

class Request < ActiveRecord::Base
  attr_accessible :email, :from_id, :to_id, :data, :from, :to, :expires_at

  include AASM

  belongs_to :from, :class_name => "User", :foreign_key => "from_id"
  belongs_to :to, :class_name => "User", :foreign_key => "to_id"

  before_create :generate_key
  
  serialize :data

  aasm :column => :state do
    state :new, :initial => true
    state :delivered
    state :viewed
    state :accepted
    state :rejected
    state :canceled
    
    event :mark_as_delivered do
      transitions :from => :new,            :to => :delivered
    end

    event :mark_as_viewed do
      transitions :sent => :delivered,      :to => :viewed
    end

    event :mark_as_accepted do
      transitions :from => :new,            :to => :accepted
      transitions :from => :delivered,      :to => :accepted
      transitions :sent => :viewed,         :to => :accepted
    end

    event :mark_as_rejected do
      transitions :from => :delivered,      :to => :rejected
    end

    event :mark_as_canceled do
      transitions :from => :new,            :to => :canceled
      transitions :from => :delivered,      :to => :canceled
      transitions :sent => :viewed,         :to => :canceled
    end
  end

  def self.find_or_create(email)
    find_by_email(email) || create(:email => email) 
  end

  def lander_url
    raise "lander_url method must be implemented by a subclass"
  end

  def deliver
    raise "deliver method must be implemented by a subclass"
  end

  def expired?
    return false if expires_at.nil?
    Time.now > expires_at
  end

  def expire_in(interval)
    self.update_attributes(:expires_at => Time.now + interval)
  end

protected

  def generate_key
    self.key = Tr8nClientSdk::Config.guid if key.nil?
  end
  
end
