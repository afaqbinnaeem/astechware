# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'ahmad@astechware.com'
  layout 'mailer'
end
