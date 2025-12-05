class HomeController < ApplicationController
  protect_from_forgery except: [:submit_form]

  def index
    @page_title = "A'sTechware Dashboard"
    @page_description = "Landing Page for A'sTechware. Transforming future with technology."
    @page_keywords = "A'sTechware, Best Software House, Best Digital Agency in Pakistan"
  end

  def submit_form
    @form = Form.new(form_params)
    ContactFormMailer.submit_contact_form(@form).deliver
    redirect_to root_path, notice: "Successfully Submitted Response."
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
end
