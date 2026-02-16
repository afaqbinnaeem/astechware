# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class RecaptchaVerificationService
  VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify'.freeze

  def self.verify(token, remote_ip = nil)
    new(token, remote_ip).verify
  end

  def initialize(token, remote_ip = nil)
    @token = token
    @remote_ip = remote_ip
  end

  def verify
    return { success: false, error: 'Token is missing' } if @token.blank?

    response = make_request
    parse_response(response)
  end

  private

  def make_request
    uri = URI(VERIFY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(
      secret: secret_key,
      response: @token,
      remoteip: @remote_ip
    )

    http.request(request)
  end

  def parse_response(response)
    body = JSON.parse(response.body)
    {
      success: body['success'] == true,
      score: body['score'],
      action: body['action'],
      challenge_ts: body['challenge_ts'],
      hostname: body['hostname'],
      error_codes: body['error-codes']
    }
  rescue JSON::ParserError => e
    Rails.logger.error "reCAPTCHA verification failed: #{e.message}"
    { success: false, error: 'Invalid response from reCAPTCHA' }
  end

  def secret_key
    ENV['RECAPTCHA_SECRET_KEY'] || Rails.application.credentials.dig(:recaptcha, :secret_key)
  end
end
