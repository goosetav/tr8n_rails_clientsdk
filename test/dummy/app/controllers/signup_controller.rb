class SignupController < ApplicationController

  def index
    if request.post?
      email = params[:email].to_s.strip
      if email.blank?
        trfe("Email must be provided.")
        return redirect_to(:controller => :welcome)
      end

      user = User.find_by_email(email)
      return trfe("This email has already been registered.") if user

      SignupRequest.find_or_create(email).deliver

      trfn("We have emailed you instructions on how to complete your registration.")
      return redirect_to(:controller => :login)
    end
  end

  def lander
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
  #   if request.post?
  #     if params[:email].blank?
  #       trfe("Email must be provided")
  #     else  
  #       user = User.find_by_email(params[:email])
  #       return trfe("We could not find this email in our system") unless user

  #       @req = PasswordResetRequest.create(:email => params[:email])
  #       @req.expire_in(5.minutes)
  #       @req.delay.deliver

  #       pp @req

  #       trfn("We emailed you instructions on how to reset your password")
  #       redirect_to("/login")
  #     end  
  #   end
  end

  def reset_password
    # @req = PasswordResetRequest.find_by_key(params[:id])

    # pp @req


    # unless @req
    #   trfe("This request is not valid")
    #   return redirect_to("/")
    # end

    # if @req.expired?
    #   trfe("This request has expired")
    #   return redirect_to("/")
    # end

    # @user = User.find_by_email(@req.email)
    # unless @user
    #   trfe("This request is not valid")
    #   return redirect_to("/")
    # end

    # if request.post?
    #   if params[:user][:password].blank?
    #     return trfe("Password may not be blank")
    #   end

    #   if params[:user][:password] != params[:user][:password_confirmation]
    #     return trfe("Passwords don't match")
    #   end

    #   @user.password =  params[:user][:password]
    #   @user.encrypt_password
    #   @user.save

    #   trfn("Your password has been reset")
    #   return redirect_to("/login")
    # end    
  end

      
end
