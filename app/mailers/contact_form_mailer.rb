class ContactFormMailer < ApplicationMailer

	def submit_contact_form(form)
		@form = form
		mail( to: "info@astechware.com",
    subject: 'You Have A Query Pending at astechware.com',
    from: @form.email )
	end

end
