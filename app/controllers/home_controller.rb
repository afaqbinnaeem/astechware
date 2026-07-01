class HomeController < ApplicationController
  protect_from_forgery except: [:submit_form, :unsubscribe_me]

  def index
    @page_title = "A'sTechware Dashboard"
    @page_description = "Landing Page for A'sTechware. Transforming future with technology."
    @page_keywords = "A'sTechware, Best Software House, Best Digital Agency in Pakistan"
  end

  def about
  end

  def services
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
      'medical-voice-ai' => { title: 'HIPAA Voice Booking & AI Scribe — LLM Never Sees Patient Names' },
      'flss-legal-process-serving' => { title: 'Process Serving Platform — Court-Defensible Multi-Tenant SaaS' },
      'ai-deal-analyzer' => { title: 'AI Real Estate Deal Analyzer, From Address to Investment Decision in 90 Seconds' },
      'shoreline-waste-logistics' => { title: 'Geospatial Logistics & Fleet Orchestration Platform' },
      'vestra-payments' => { title: 'Automated Payment Settlement & Escrow Engine' },
      'zofi-cash-fintech' => { title: 'Liquidity-as-a-Service & Automated Payroll Settlement Engine' },
      'golfpay360-saas' => { title: 'Multi-Tenant Hospitality Orchestration & POS Engine' },
      'red-dragon-hvac' => { title: 'Automated Field-Proof Marketing & Local SEO Engine' },
      'eventvesta-ai-marketing' => { title: 'AI Marketing OS for Event Promoters' },
      'instashowing-real-estate' => { title: 'Real Estate Transaction Coordination & Availability Engine' },
      'word-of-mouth-modernization' => { title: 'Enterprise Legacy-to-Cloud Marketplace Transformation' },
      'restaurant-resource-rescue' => { title: 'High-Performance Search & Inventory Recovery' },
      'construction-management-platform' => { title: 'Multi-Company Construction Management Platform: Traceable Estimates to QuickBooks' },
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
      verification_result = RecaptchaVerificationService.verify(
        recaptcha_token,
        request.remote_ip,
        expected_action: 'contact'
      )
      
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
