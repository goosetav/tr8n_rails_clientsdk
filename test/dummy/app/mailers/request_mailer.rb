class RequestMailer < ActionMailer::Base
  default from: Tr8nClientSdk::Config.contact_email
  layout 'mailer'

  def signup(req)
    @req = req
    mail to: req.email, subject: "Complete your registration with #{Tr8nClientSdk::Config.site_title}".translate
  end  

  def reset_password(req)
    @req = req
    mail to: req.email, subject: "Reset your password at #{Tr8nClientSdk::Config.site_title}".translate
  end
  
end
