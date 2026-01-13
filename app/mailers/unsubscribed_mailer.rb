class UnsubscribedMailer < ApplicationMailer
  def notify_unsubscribe(email)
    @email = email
    mail(
      to: "ahmad@astechware.com",
      subject: "User Unsubscribed"
    )
  end
end
