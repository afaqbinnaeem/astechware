class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("GOOGLE_WORKSPACE_SMTP_USER", "ahmad@astechwareaiagency.com")
  layout "mailer"
end
