class HomeController < ApplicationController
  protect_from_forgery except: [:submit_form, :unsubscribe_me]

  def index
    @page_title = "A'sTechware Dashboard"
    @page_description = "Landing Page for A'sTechware. Transforming future with technology."
    @page_keywords = "A'sTechware, Best Software House, Best Digital Agency in Pakistan"
  end

  def about
  end

  def clients
  end

  def ai_agents
  end

  def submit_form
    @form = Form.new(form_params)
    ContactFormMailer.submit_contact_form(@form).deliver
    redirect_path = request.referer&.include?('/contact') ? contact_path : root_path
    redirect_to redirect_path, notice: "Successfully Submitted Response."
  end

  private def form_params
    params.require(:form).permit(:reason, :name, :email, :company_name, :cover_letter)
  end

  def ourTeam
  end

  def teamDetail
  end
  
  def blog
  end

  def portfolio
  end

  def projects
  end

  def contact
  end

  def derisk_projects
  end

  def privacy_policy
  end

  def unsubscribe
  end

  def unsubscribe_me
    email = params[:email]
    if email.present?
      UnsubscribedMailer.notify_unsubscribe(email).deliver
      redirect_to root_path, notice: "Successfully unsubscribed."
    else
      redirect_to root_path, alert: "Failed to unsubscribe."
    end
  end
end
