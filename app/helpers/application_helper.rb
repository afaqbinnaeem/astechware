# frozen_string_literal: true

module ApplicationHelper
  # Safely get image URL for Open Graph meta tags
  # Returns absolute URL or nil if asset doesn't exist (prevents 500 errors)
  def safe_og_image_url(image_name = 'logo-colored.png')
    url = image_url(image_name)
    # Ensure absolute URL for Open Graph (required by LinkedIn, Facebook, etc.)
    if url.present? && !url.start_with?('http')
      # If relative URL, make it absolute
      url = "#{request.protocol}#{request.host_with_port}#{url}"
    end
    url
  rescue StandardError => e
    # Log error but don't crash - return nil or fallback URL
    Rails.logger.warn "Failed to generate image URL for #{image_name}: #{e.message}"
    nil
  end

  # Safely get request URL for Open Graph meta tags
  def safe_request_url
    request.url
  rescue StandardError => e
    Rails.logger.warn "Failed to get request URL: #{e.message}"
    root_url
  end

  # Get base URL (protocol + host) for structured data
  def base_url
    begin
      url = safe_request_url
      url.split('/')[0..2].join('/')
    rescue StandardError => e
      Rails.logger.warn "Failed to get base URL: #{e.message}"
      root_url
    end
  end

  # Get reCAPTCHA site key for frontend
  def recaptcha_site_key
    ENV['RECAPTCHA_SITE_KEY'] || Rails.application.credentials.dig(:recaptcha, :site_key)
  end
end
