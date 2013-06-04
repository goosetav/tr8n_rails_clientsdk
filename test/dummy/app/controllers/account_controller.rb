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

class AccountController < ApplicationController
  before_filter :redirect_if_not_logged_in

  def index
    if request.post?
      if params[:name].blank?
        return trfe("Name cannot be blank")
      end

      current_user.name = params[:name]

      current_user.gender = params[:gender].blank? ? nil : params[:gender]
      current_user.save

      return redirect_to_source if params[:header]
    end
  end

  def email_password
    if request.post?
      if current_user.password_set? 
        if params[:current_password].blank?
          return trfe("Current password cannot be blank")
        end

        user = User.authenticate(current_user.email, params[:current_password])
        if user != current_user
          return trfe("The current password you provided is incorrect")
        end
      end

      if params[:new_password].blank?
        return trfe("New password cannot be blank")
      end

      if params[:confirm_new_password] != params[:new_password]
        return trfe("New passwords don't match")
      end

      current_user.set_password(params[:new_password])

      trfn("Your new password has been saved")
    end
  end

  def close_account
    if request.post?
      vparams = {
        :privatekey => "6LdF5dMSAAAAAP8ObTerBEmjLql2ycy-FxRBEdKI",
        :remoteip => request.remote_ip,
        :challenge => params[:recaptcha_challenge_field],
        :response => params[:recaptcha_response_field]
      }

      conn = Faraday.new(:url => "http://www.google.com")
      response = conn.get('/recaptcha/api/verify', vparams)
      result = response.body || "false"
      
      if result.index("false")
        return trfe("The Captcha you've added is incorrect. Please try again.")
      end

      current_user.destroy      
      logout!
      trfe("Your account has been removed")

      return redirect_to("/login/out")
    end
  end

end
