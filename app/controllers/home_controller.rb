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

  def reviews
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
      'medical-voice-ai' => {
        title: 'HIPAA Voice Booking & AI Scribe, LLM Never Sees Patient Names',
        description: "Healthcare AI case study: HIPAA-compliant voice booking and AI medical scribe with PHI protection. Production engineering for clinics and multi-location practices.",
        keywords: 'healthcare AI, HIPAA compliant AI, medical voice automation, AI medical scribe, voice AI healthcare, healthcare software engineering partner, case study'
      },
      'flss-legal-process-serving' => {
        title: 'Process Serving Platform, Court Defensible Multi Tenant SaaS',
        description: "Legal tech case study: court-defensible process serving SaaS with multi-tenant architecture, AI document parsing, and audit-grade data flows.",
        keywords: 'legal tech software, legal operations automation, process serving SaaS, legal software engineering, law firm software, case study'
      },
      'ai-deal-analyzer' => {
        title: 'AI Real Estate Deal Analyzer, From Address to Investment Decision in 90 Seconds',
        description: "Real estate AI case study: investment deal analyzer that turns property addresses into investment decisions in 90 seconds with production AI automation.",
        keywords: 'real estate AI, investment analysis automation, real estate software, property analysis automation, case study'
      },
      'shoreline-waste-logistics' => {
        title: 'Geospatial Logistics & Fleet Orchestration Platform',
        description: "Logistics automation case study: geospatial fleet orchestration, route optimization, and dispatch platform for waste logistics and trucking operations.",
        keywords: 'logistics automation, trucking dispatch software, route optimization, fleet management, dispatch automation, case study'
      },
      'vestra-payments' => {
        title: 'Automated Payment Settlement & Escrow Engine',
        description: "Real estate fintech case study: automated payment settlement and escrow engine for property management operations.",
        keywords: 'real estate payments software, property management automation, payment settlement, fintech engineering partner, case study'
      },
      'zofi-cash-fintech' => {
        title: 'Liquidity as a Service & Automated Payroll Settlement Engine',
        description: "Fintech case study: earned wage access and automated payroll settlement engine with production-grade financial infrastructure.",
        keywords: 'fintech software development, earned wage access, payroll settlement automation, financial services automation, case study'
      },
      'golfpay360-saas' => {
        title: 'Multi Tenant Hospitality Orchestration & POS Engine',
        description: "B2B SaaS case study: multi-tenant hospitality orchestration and POS engine for golf and hospitality operations.",
        keywords: 'B2B SaaS development, hospitality software, multi tenant SaaS, POS platform engineering, case study'
      },
      'red-dragon-hvac' => {
        title: 'Automated Field Proof Marketing & Local SEO Engine',
        description: "HVAC field service case study: automated field proof collection, local SEO engine, and field operations marketing automation.",
        keywords: 'HVAC field service software, field ops automation, field service automation, local SEO automation, case study'
      },
      'eventvesta-ai-marketing' => {
        title: 'AI Marketing OS for Event Promoters',
        description: "AI automation case study: marketing operating system for event promoters with AI-driven outreach and campaign automation.",
        keywords: 'AI marketing automation, event marketing software, workflow automation, AI growth engine, case study'
      },
      'instashowing-real-estate' => {
        title: 'Real Estate Transaction Coordination & Availability Engine',
        description: "Real estate software case study: transaction coordination and property showing availability engine for real estate teams.",
        keywords: 'real estate software, property showing automation, transaction coordination, real estate operations software, case study'
      },
      'word-of-mouth-modernization' => {
        title: 'Enterprise Legacy to Cloud Marketplace Transformation',
        description: "Platform modernization case study: enterprise legacy to cloud marketplace transformation with zero-downtime migration.",
        keywords: 'platform modernization, legacy software engineering partner, marketplace transformation, cloud migration, case study'
      },
      'restaurant-resource-rescue' => {
        title: 'High Performance Search & Inventory Recovery',
        description: "Operations software case study: high-performance search and inventory recovery platform for restaurant resource management.",
        keywords: 'operations software, inventory automation, search platform engineering, custom software development, case study'
      },
      'construction-management-platform' => {
        title: 'Multi Company Construction Management Platform: Traceable Estimates to QuickBooks',
        description: "Construction software case study: multi-company construction management platform with traceable estimates, subcontracting, and QuickBooks integration.",
        keywords: 'construction software development, construction management platform, subcontract automation, general contractor software, case study'
      }
    }

    case_study = case_studies[slug]
    raise ActionController::RoutingError, 'Not Found' if case_study.blank?

    @case_study_seo = case_study.merge(slug: slug)

    set_meta_tags(
      title: "#{case_study[:title]} | Case Study",
      description: case_study[:description],
      keywords: case_study[:keywords]
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

  def gcc
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
