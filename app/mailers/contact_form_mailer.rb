class ContactFormMailer < ApplicationMailer
    def submit_contact_form(form)
		@form = form
		mail(
			to: "ahmad@astechware.com",
			subject: 'You Have A Query Pending at astechware.com',
			reply_to: @form.email # <-- safe way to use user's email
		)
    end
end