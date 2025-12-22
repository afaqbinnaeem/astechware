# frozen_string_literal: true

module ApplicationHelper
  # Safely get image URL for Open Graph meta tags
  # Returns absolute URL or nil if asset doesn't exist (prevents 500 errors)
  def safe_og_image_url(image_name = 'logo.png')
    image_url(image_name)
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
end
