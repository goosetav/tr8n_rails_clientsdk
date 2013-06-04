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

class LoginController < ApplicationController

  def index    
    if request.post?
      user = login(params[:email], params[:password])
      if user
        redirect_to("/home")
      else
        trfe('Incorrect email or password')
      end      
    end
  end

  def out
    logout!
    trfn("You have been logged out")
  end

  def signup
    unless request.post?
      trfe('Cannot access this URL')
      return redirect_to(:controller => :welcome)
    end
    
    email = params[:email].to_s.strip
    if email.blank?
      trfe("Email must be provided.")
      return redirect_to(:controller => :welcome)
    end

    user = User.find_by_email(email)
    return trfe("This email has already been registered.") if user

    SignupRequest.find_or_create(email).deliver

    trfn("We have emailed you instructions on how to complete your registration.")
    redirect_to(:controller => :login)
  end

  def signup_lander
    @req = SignupRequest.find_by_key(params[:id]) if params[:id]

    unless @req
      trfe("Signup request was not found")
      return redirect_to(:controller => :login)
    end

    if @req.accepted?
      trfe("You have already accepted this request. Please sign in with your email and password.")
      return redirect_to(:controller => :login)
    end
    
    if request.post?
      user = User.new(params[:user].merge(:email => @req.email))
      if user.save
        @req.mark_as_accepted!
        @req.update_attributes(:to => user)

        login!(user)

        trfn('Thank you for registering.')
        return redirect_to(:controller => :home)
      else
        trfe(user.errors.full_messages.first)
      end  
    else
      @user = User.new
    end
  end

  def forgot_password
    if request.post?
      email = params[:email].to_s.strip
      if email.blank?
        trfe("Email must be provided.")
        return
      end

      user = User.find_by_email(email)
      return trfe("We could not find this email in our system") unless user

      req = PasswordResetRequest.find_or_create(email)
      req.expire_in(5.minutes)
      req.deliver

      trfn("We emailed you instructions on how to reset your password")
      return redirect_to("/login")
    end
  end

  def reset_password
    @req = PasswordResetRequest.find_by_key(params[:id]) if params[:id]

    unless @req
      trfe("Password reset request was not found")
      return redirect_to(:controller => :login)
    end

    if @req.expired?
      trfe("This request has expired")
      return redirect_to(:controller => :login)
    end

    @user = User.find_by_email(@req.email)
    unless @user
      trfe("This request is not valid")
      return redirect_to(:controller => :login)
    end

    if request.post?
      if params[:user][:password].blank?
        return trfe("Password may not be blank")
      end

      if params[:user][:password] != params[:user][:password_confirmation]
        return trfe("Passwords don't match")
      end

      @user.set_password(params[:user][:password])

      trfn("Your password has been reset")
      return redirect_to(:controller => :login)
    end    
  end

      
end
