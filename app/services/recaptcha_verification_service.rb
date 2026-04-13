# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class RecaptchaVerificationService
  VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify'.freeze
  DEFAULT_MINIMUM_SCORE = 0.5

  def self.verify(token, remote_ip = nil, expected_action: nil, minimum_score: nil)
    new(token, remote_ip, expected_action: expected_action, minimum_score: minimum_score).verify
  end

  def initialize(token, remote_ip = nil, expected_action: nil, minimum_score: nil)
    @token = token
    @remote_ip = remote_ip
    @expected_action = expected_action
    @minimum_score = minimum_score
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
    base = {
      success: body['success'] == true,
      score: body['score'],
      action: body['action'],
      challenge_ts: body['challenge_ts'],
      hostname: body['hostname'],
      error_codes: body['error-codes']
    }

    return { **base, success: false, error: 'reCAPTCHA rejected' } unless base[:success]

    # v3 returns score + action; v2 checkbox responses have no score.
    if body.key?('score')
      min = (@minimum_score || configured_minimum_score).to_f
      score = body['score'].to_f
      if score < min
        Rails.logger.warn "reCAPTCHA v3 score too low: #{score} (min #{min})"
        return { **base, success: false, error: 'reCAPTCHA score too low' }
      end

      if @expected_action.present? && body['action'].to_s != @expected_action.to_s
        Rails.logger.warn "reCAPTCHA v3 action mismatch: expected #{@expected_action}, got #{body['action']}"
        return { **base, success: false, error: 'reCAPTCHA action mismatch' }
      end
    end

    base
  rescue JSON::ParserError => e
    Rails.logger.error "reCAPTCHA verification failed: #{e.message}"
    { success: false, error: 'Invalid response from reCAPTCHA' }
  end

  def configured_minimum_score
    ENV['RECAPTCHA_MINIMUM_SCORE'].presence&.to_f || DEFAULT_MINIMUM_SCORE
  end

  def secret_key
    ENV['RECAPTCHA_SECRET_KEY'] || Rails.application.credentials.dig(:recaptcha, :secret_key)
  end
end
