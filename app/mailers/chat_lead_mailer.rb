# frozen_string_literal: true

class ChatLeadMailer < ApplicationMailer
  def notify_lead(contact_info:, conversation_summary: nil)
    @name = contact_info[:name]
    @email = contact_info[:email]
    @company_name = contact_info[:company_name]
    @description = contact_info[:description]
    @conversation_summary = conversation_summary
    @timestamp = Time.current

    subject_line = @name.present? ? "New Lead from Chat Widget - #{@name}" : 'New Lead from Chat Widget'

    mail(
      to: 'ahmad@astechware.com',
      subject: subject_line,
      reply_to: @email.presence || 'ahmad@astechware.com'
    )
  end
end
