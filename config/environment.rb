# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

ActionMailer::Base.smtp_settings = {
  :user_name => 'apikey', # This is the string literal 'apikey', NOT the ID of your API key
  :password => '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', # This is the secret sendgrid API key which was issued during API key creation
  :domain => 'astechware.com',
  :address => 'smtp.sendgrid.net',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}