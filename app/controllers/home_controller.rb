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

  def ai_agent_development
  end

  def machine_learning
  end

  def platform_modernization
  end

  def custom_software
  end

  def api_integrations
  end

  def devops_engineering
  end

  def case_study
    slug = params[:slug].to_s

    case_studies = {
      'medical-voice-ai' => { title: 'Medical Voice AI & Clinical Triage' },
      'legal-contract-ai' => { title: 'Private AI Pipeline for Contract Discovery' },
      'shoreline-waste-logistics' => { title: 'Shoreline Waste Logistics & Route AI' },
      'vestra-payments' => { title: 'Vestra Payment Orchestration' },
      'zofi-cash-fintech' => { title: 'Zofi Cash Salary Advance (EWA) Platform' },
      'golfpay360-saas' => { title: 'GolfPay360 High-Concurrency Booking' },
      'red-dragon-hvac' => { title: 'Red Dragon HVAC MMS-to-Social Pipeline' },
      'instashowing-real-estate' => { title: 'InstaShowing Real Estate Platform' },
      'athenahealth-sync' => { title: 'Athenahealth Enterprise Integration' },
      'ai-medical-scribe' => { title: 'Ambient AI Medical Scribe' },
      'word-of-mouth-modernization' => { title: 'Word of Mouth Platform Modernization' },
      'restaurant-resource-rescue' => { title: 'Restaurant Resource Rescue & Search AI' },
      'legal-affidavit-engine' => { title: 'Legal Affidavit & Document AI' }
    }

    case_study = case_studies[slug]
    raise ActionController::RoutingError, 'Not Found' if case_study.blank?

    set_meta_tags(
      title: "#{case_study[:title]} | Case Study",
      description: "A'sTechware case study: #{case_study[:title]}. Production-ready engineering for high-stakes environments.",
      keywords: 'case study, production engineering, AI automation, platform engineering'
    )

    render "home/case_studies/#{slug}"
  end

  def submit_form
    # Verify reCAPTCHA if enabled
    if recaptcha_enabled?
      recaptcha_token = params['g-recaptcha-response']
      verification_result = RecaptchaVerificationService.verify(recaptcha_token, request.remote_ip)
      
      unless verification_result[:success]
        redirect_path = request.referer&.include?('/contact') ? contact_path : root_path
        redirect_to redirect_path, alert: "reCAPTCHA verification failed. Please try again."
        return
      end
    end

    @form = Form.new(form_params)
    ContactFormMailer.submit_contact_form(@form).deliver
    redirect_path = request.referer&.include?('/contact') ? contact_path : root_path
    redirect_to redirect_path, notice: "Successfully Submitted Response."
  end

  private

  def form_params
    params.require(:form).permit(:reason, :name, :email, :company_name, :cover_letter)
  end

  def recaptcha_enabled?
    ENV['RECAPTCHA_SITE_KEY'].present? || Rails.application.credentials.dig(:recaptcha, :site_key).present?
  end

  def ourTeam
  end

  def teamDetail
  end
  
  def blog
  end

  def portfolio
    # Case studies are 100% hardcoded in app/views/home/portfolio.html.erb (no DB, no lib).
  end

  def projects
  end

  def contact
  end

  def derisk_projects
  end

  def methodology
  end

  def industry_healthcare
  end

  def industry_legal
  end

  def industry_financial
  end

  def industry_b2b_saas
  end

  def industry_professional_services
  end

  def industry_edtech
  end

  def privacy_policy
  end

  def terms_of_service
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
