class ApplicationController < ActionController::Base
  protect_from_forgery


private 

  def current_user
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def current_locale
    @current_locale ||= begin      
      if params[:locale]
        session[:locale] = params[:locale]
        save_locale = true
      elsif current_user and current_user.locale != nil
        session[:locale] = current_user.locale
      elsif session[:locale] == nil
        session[:locale] = tr8n_user_preffered_locale
        save_locale = (session[:locale] != Tr8nClientSdk::Config.default_locale)
      end

      if save_locale and current_user
        current_user.update_attributes(:locale => session[:locale])
        # Tr8nClientSdk::LanguageUser.find_or_create(current_user, Tr8nClientSdk::Language.for(session[:locale]))
      end

      session[:locale]
    end
  end
  helper_method :current_locale

  def language
    Tr8nClientSdk::Config.current_language
  end
  helper_method :language

  def login(email, password, opts = {})
    user = User.authenticate(email, password)
    login!(user) if user
    user
  end

  def login!(user)
    session[:user_id] = user.id
  end

  def logout!
    session[:user_id] = nil
    @current_user = nil
    # Tr8nClientSdk::Config.reset!
    # Platform::Config.reset!
  end  
  
  def redirect_if_not_logged_in
    redirect_to("/welcome") unless current_user
  end

  def redirect_back_or_to(url)
    return redirect_to(request.env['HTTP_REFERER']) unless request.env['HTTP_REFERER'].blank?
    redirect_to(url)
  end

end
