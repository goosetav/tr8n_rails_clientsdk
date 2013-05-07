require 'bcrypt'

class User < ActiveRecord::Base
  
  include BCrypt

  attr_accessible :email, :name, :password, :password_confirmation, :gender, :locale

  attr_accessor :password, :password_confirmation
  before_save :encrypt_password

  validates_presence_of :name

  validates :email,   :presence => true, 
                      :length => {:minimum => 3, :maximum => 254},
                      :uniqueness => true,
                      :format => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i}        

  has_many :sent_requests, :class_name => "Request", :foreign_key => :from_id, :dependent => :destroy
  has_many :recieved_requests, :class_name => "Request", :foreign_key => :to_id, :dependent => :destroy

  def self.authenticate(email, password)
    user = find_by_email(email)
    return nil if user.nil? or user.crypted_password.nil? or user.salt.nil?
    if user.crypted_password == BCrypt::Engine.hash_secret(password, user.salt)
      user
    else
      nil
    end
  end

  def set_password(new_password)
    self.password = new_password
    encrypt_password
    save!
  end

  def password_set?
    not password_set_at.nil?
  end

  def encrypt_password
    if password.present?
      self.salt = BCrypt::Engine.generate_salt
      self.crypted_password = BCrypt::Engine.hash_secret(password, salt)
      self.password_set_at = Time.now
    end
  end
    
  def mugshot(size = :medium)
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "http://gravatar.com/avatar/#{gravatar_id}.png?s=48"
  end

  def to_s
    name
  end
  
  def guest?
    id.nil?
  end
end
