# frozen_string_literal: true

class ApplicationController < ActionController::Base

  def after_sign_in_path_for(*)
    root_path
  end

  def require_login
    unless current_user.present?
      flash[:error] = "You must be logged in to access this section"
      redirect_to root_path
    end
  end
end
