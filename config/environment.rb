# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Google Workspace SMTP
ActionMailer::Base.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'astechware.com',
  user_name: ENV['GOOGLE_WORKSPACE_SMTP_USER'],
  password: ENV['GOOGLE_WORKSPACE_SMTP_PASSWORD'],
  authentication: :plain,
  enable_starttls_auto: true
}