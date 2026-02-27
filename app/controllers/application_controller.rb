# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_seo_and_security_headers

  def after_sign_in_path_for(*)
    root_path
  end

  def require_login
    unless current_user.present?
      flash[:error] = "You must be logged in to access this section"
      redirect_to root_path
    end
  end

  private

  def set_seo_and_security_headers
    response.set_header("X-Robots-Tag", "index, follow")
    response.set_header("X-Content-Type-Options", "nosniff")
    response.set_header("X-Frame-Options", "SAMEORIGIN")
    response.set_header("Referrer-Policy", "strict-origin-when-cross-origin")
  end
end
