# frozen_string_literal: true

module ApplicationHelper
  # Niche blog categories. key => display name and the page the category belongs to.
  BLOG_CATEGORIES = {
    "private-clinics" => { name: "Private clinics", path: "/solutions/private-clinics" },
    "healthcare" => { name: "Healthcare & EHR", path: "/solutions/healthcare" },
    "legal" => { name: "Legal & process serving", path: "/solutions/legal" },
    "construction" => { name: "Construction", path: "/solutions/construction" },
    "logistics" => { name: "Logistics & field service", path: "/solutions/logistics" },
    "home-services" => { name: "Home services & HVAC", path: "/solutions/home-services" },
    "real-estate" => { name: "Real estate", path: "/solutions/real-estate" },
    "fintech" => { name: "Fintech & payments", path: "/solutions/financial" },
    "b2b-saas" => { name: "B2B SaaS", path: "/solutions/b2b-saas" },
    "professional-services" => { name: "Professional services", path: "/solutions/professional-services" },
    "edtech" => { name: "Education technology", path: "/solutions/education-technology" },
    "fitness" => { name: "Fitness studios", path: "/solutions/fitness-studios" },
    "general" => { name: "General", path: "/services" }
  }.freeze

  HEALTHCARE_BLOG_SLUGS = %w[
    hipaa-compliant-ai-healthcare-companies-guide
    whatsapp-voice-ai-agent-demo
  ].freeze

  # Render a link only when the named route helper exists (new pages ship gradually).
  def route_helper_defined?(helper_name)
    Rails.application.routes.url_helpers.respond_to?(helper_name)
  end

  def link_to_if_route(name, helper_name, html_options = {}, &block)
    return "".html_safe unless route_helper_defined?(helper_name)

    path = public_send(helper_name)
    if block_given?
      link_to(path, html_options, &block)
    else
      link_to(name, path, html_options)
    end
  end

  # Safely get image URL for Open Graph meta tags
  # Returns absolute URL or nil if asset doesn't exist (prevents 500 errors)
  def safe_og_image_url(image_name = 'favicon.svg')
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

  # Canonical URL: strip query params, normalize trailing slash, use production host in production
  def canonical_url
    base = Rails.env.production? ? "https://astechware.com" : "#{request.protocol}#{request.host_with_port}"
    path = request.path.presence || "/"
    path = path.sub(/\/*\z/, "")  # strip trailing slashes
    path = "/" if path.blank?
    "#{base}#{path}"
  rescue StandardError => e
    Rails.logger.warn "Failed to get canonical URL: #{e.message}"
    root_url
  end

  # Full URL for OG image. LinkedIn requires PNG/JPG (not SVG). Prefer public/og-image.png.
  def seo_og_image_url
    base = Rails.env.production? ? "https://astechware.com" : "#{request.protocol}#{request.host_with_port}"
    image_path =
      if Rails.public_path.join("og-image.png").exist?
        "/og-image.png?v=2"
      elsif Rails.public_path.join("web-app-manifest-512x512.png").exist?
        "/web-app-manifest-512x512.png?v=2"
      else
        "/favicon-96x96.png"
      end
    "#{base}#{image_path}"
  end

  def seo_og_image_type
    "image/png"
  end

  def seo_og_image_dimensions
    if Rails.public_path.join("og-image.png").exist?
      { width: 512, height: 512 }
    elsif Rails.public_path.join("web-app-manifest-512x512.png").exist?
      { width: 512, height: 512 }
    else
      { width: 96, height: 96 }
    end
  end

  # Get reCAPTCHA site key for frontend
  def recaptcha_site_key
    ENV['RECAPTCHA_SITE_KEY'] || Rails.application.credentials.dig(:recaptcha, :site_key)
  end
  # Blog articles for Insights & Resources landing (path, metadata). Replace with DB later.
  def blog_articles_list
    [
      {
        slug: "ai-receptionist-for-clinics",
        path: -> { blog_show_path("ai-receptionist-for-clinics") },
        title: "AI receptionist for clinics: what it does, what it costs to run, and what to check",
        seo_title: "AI Receptionist for Clinics: A Buyer's Guide",
        meta_description: "What an AI receptionist for clinics does: answering calls, booking patients and handing off to staff, plus the costs to run it and the checks before you buy.",
        keywords: "AI receptionist for clinics, AI phone answering for medical practice, after-hours clinic calls, voice AI appointment booking, virtual receptionist clinic",
        category: "Private clinics",
        category_slug: "private-clinics",
        excerpt_short: "What an AI receptionist for clinics does: answering calls, booking patients and handing off to staff, plus the costs to run it and the checks before you buy.",
        excerpt_long: "A clinic's phone rings most when the front desk is busiest. Calls after 5pm go to voicemail, and many of those patients book somewhere else. An AI receptionist for clinics answers every call, books into your real schedule and hands anything clinical to a person. Here is what it does, what it costs to run and what to check before you buy or build one.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Clinic front desk phone with an AI receptionist booking an appointment",
        faq: [
        { q: "Is an AI receptionist HIPAA compliant?", a: "No software is compliant on its own. A system can be HIPAA-ready, with BAAs, encryption, audit logs and access controls. Your clinic's own policies and staff training complete the picture." },
        { q: "Will patients know they're talking to AI?", a: "They should. Say so at the start of the call and always offer a person. Most patients care more about getting booked quickly than about who books them." }
        ],
        case_study_path: "/case-studies/medical-voice-ai",
        integration_path: "/integrations/twilio",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "ai-scribe-for-clinics-soap-notes",
        path: -> { blog_show_path("ai-scribe-for-clinics-soap-notes") },
        title: "AI scribe for clinics: how SOAP note automation works from visit to EHR",
        seo_title: "AI Scribe for Clinics: How SOAP Notes Work",
        meta_description: "How an AI scribe for clinics turns a visit into a draft SOAP note: recording, transcription, de-identification, provider approval and the push into your EHR.",
        keywords: "AI scribe for clinics, SOAP note automation, AI medical scribe, ambient clinical documentation, AI clinical notes EHR",
        category: "Private clinics",
        category_slug: "private-clinics",
        excerpt_short: "How an AI scribe for clinics turns a visit into a draft SOAP note: recording, transcription, de-identification, provider approval and the push into your EHR.",
        excerpt_long: "Providers spend hours each evening writing notes from memory. An AI scribe for clinics listens to the visit, drafts a SOAP note in your template, and waits for the provider to approve it before anything enters the chart. Here is how the flow works and what to check before you pick one.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Provider reviewing an AI-drafted SOAP note before it goes into the EHR",
        faq: [
        { q: "Does an AI scribe keep the visit recording?", a: "It shouldn't need to. In our design, audio is streamed for transcription and then discarded." },
        { q: "Which EHRs can it write notes into?", a: "Any EHR that gives write access through an API. In our build that was athenahealth through FHIR R4. Check which write permissions your EHR vendor allows before you start." }
        ],
        case_study_path: "/case-studies/medical-voice-ai",
        integration_path: "/integrations/fhir-ehr",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "process-server-software-guide",
        path: -> { blog_show_path("process-server-software-guide") },
        title: "Process server software: what to look for, and when to build your own",
        seo_title: "Process Server Software: What to Look For",
        meta_description: "What process server software needs to do: intake from email and PDFs, dispatch with GPS proof, affidavits and invoicing, and when building your own pays off.",
        keywords: "process server software, process serving management software, process server app, service of process software, legal process serving platform",
        category: "Legal & process serving",
        category_slug: "legal",
        excerpt_short: "What process server software needs to do: intake from email and PDFs, dispatch with GPS proof, affidavits and invoicing, and when building your own pays off.",
        excerpt_long: "Most process serving companies start on email, spreadsheets and a phone. It works until the volume grows. Then jobs get missed, servers chase the office for details, and affidavits take longer than the serve itself. Here is what good process server software needs to do, and how to decide between buying a product and building your own.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Process server app showing a job with GPS-stamped service attempts",
        faq: [
        { q: "Can the software read service requests straight from email?", a: "Yes. It reads the email and the attached PDFs and fills the job record for someone to check." },
        { q: "Does GPS proof hold up in court?", a: "GPS location, timestamps and photos make your record of each attempt much stronger. What a court accepts depends on your jurisdiction's rules, so check local requirements." }
        ],
        case_study_path: "/case-studies/flss-legal-process-serving",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "automate-affidavit-of-service",
        path: -> { blog_show_path("automate-affidavit-of-service") },
        title: "How to automate affidavits of service (without losing control)",
        seo_title: "How to Automate Affidavits of Service",
        meta_description: "How affidavit of service automation works: job data, attempts, GPS and photos fill a court-ready template, and a person still checks every line.",
        keywords: "affidavit of service automation, proof of service template, affidavit of service software, e-sign affidavit of service, process server affidavit generator",
        category: "Legal & process serving",
        category_slug: "legal",
        excerpt_short: "How affidavit of service automation works: job data, attempts, GPS and photos fill a court-ready template, and a person still checks every line.",
        excerpt_long: "An affidavit of service is often the slowest part of a serve. Someone copies job details, attempt dates and notes into a court form, formats it and chases a signature. All of that information already exists in your system. Affidavit of service automation puts it in the right template so the server only has to review and sign.",
        read_time: "5 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Affidavit of service generated from job data and ready for e-signature",
        faq: [
        { q: "Can an affidavit of service be signed electronically?", a: "Many jurisdictions accept e-signatures, but some still need a notary or commissioner." },
        { q: "What if each court wants a different format?", a: "Keep one template per format. The court on the job selects the template automatically, so staff never pick the wrong one." }
        ],
        case_study_path: "/case-studies/flss-legal-process-serving",
        integration_path: "/integrations/docusign",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "construction-estimating-automation",
        path: -> { blog_show_path("construction-estimating-automation") },
        title: "Construction estimating from plan PDFs: what automation can and can't do",
        seo_title: "Construction Estimating from Plan PDFs",
        meta_description: "How construction estimating automation drafts estimates from plan PDFs: reading quantities, applying your own prices and keeping an estimator in control.",
        keywords: "construction estimating automation, AI construction estimating, estimate from plan PDF, construction takeoff automation, contractor estimating software",
        category: "Construction",
        category_slug: "construction",
        excerpt_short: "How construction estimating automation drafts estimates from plan PDFs: reading quantities, applying your own prices and keeping an estimator in control.",
        excerpt_long: "Estimating eats the evenings of most contractors. Someone reads a stack of plan PDFs, pulls quantities, writes line items and prices them by hand. Construction estimating automation drafts most of that from the documents and leaves the judgement to the estimator. Here is what works, what doesn't, and what we learned building one.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Plan PDF on one side and a drafted line-item estimate on the other",
        faq: [
        { q: "Can AI do a full takeoff from drawings?", a: "It can draft quantities from schedules, notes and clearly labelled sheets." },
        { q: "Will it use my prices or generic ones?", a: "Yours. Generic price databases don't match your subs or your clients' contracted rates. The system should learn from your own price book and past estimates." }
        ],
        case_study_path: "/case-studies/construction-management-platform",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "multi-company-construction-software-quickbooks",
        path: -> { blog_show_path("multi-company-construction-software-quickbooks") },
        title: "Running several construction companies on one platform, each with its own QuickBooks",
        seo_title: "Multi-Company Construction Software",
        meta_description: "Running more than one construction company? How one platform can handle estimates, subcontracts and invoices while each company syncs to its own QuickBooks.",
        keywords: "multi-company construction software, construction software QuickBooks integration, construction management software for multiple companies, subcontract management, QuickBooks Online construction",
        category: "Construction",
        category_slug: "construction",
        excerpt_short: "Running more than one construction company? How one platform can handle estimates, subcontracts and invoices while each company syncs to its own QuickBooks.",
        excerpt_long: "Many contractors run more than one company: a general contracting business, a specialty trade shop, a residential arm. Each one usually ends up with its own tools and its own way of working. Multi-company construction software puts them on one platform while keeping each company's books apart. Here is how it should be set up.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "One construction dashboard with three companies, each linked to its own QuickBooks",
        faq: [
        { q: "Can each company keep its own QuickBooks?", a: "Yes." },
        { q: "Does it work with QuickBooks Desktop?", a: "We build on the QuickBooks Online API. Desktop works differently and usually needs a separate connector, so check which version you use first." }
        ],
        case_study_path: "/case-studies/construction-management-platform",
        integration_path: "/integrations/quickbooks-online",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "route-planning-software-service-businesses",
        path: -> { blog_show_path("route-planning-software-service-businesses") },
        title: "Route planning software for service businesses: when static routes stop working",
        seo_title: "Route Planning Software for Service Routes",
        meta_description: "Route planning software for service businesses: when static routes waste fuel, what dynamic planning needs, and how dispatchers stay in control of the day.",
        keywords: "route planning software for service businesses, route optimization for field service, dispatch software, service route planning app, fleet route planner",
        category: "Logistics & field service",
        category_slug: "logistics",
        excerpt_short: "Route planning software for service businesses: when static routes waste fuel, what dynamic planning needs, and how dispatchers stay in control of the day.",
        excerpt_long: "Many route-based businesses still run on route sheets someone built years ago. Customers are added at the end, paused stops stay on the list, and drivers zigzag across town. Route planning software for service businesses rebuilds each day's routes from real data and lets the dispatcher make the final call.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Dispatcher map showing optimized service routes for the day",
        faq: [
        { q: "Can it use the GPS trackers already in our trucks?", a: "Usually, yes. Telematics systems such as Samsara and Geotab have APIs, so live vehicle positions can feed the dispatcher map." },
        { q: "Do drivers need a new phone?", a: "No. The driver app runs on ordinary Android and iPhone devices and stores the day's route for areas with no signal." }
        ],
        case_study_path: "/case-studies/shoreline-waste-logistics",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "proof-of-service-app-photo-gps",
        path: -> { blog_show_path("proof-of-service-app-photo-gps") },
        title: "Proof of service app: how photo and GPS logs end \"you never came\" disputes",
        seo_title: "Proof of Service App: End Pickup Disputes",
        meta_description: "A proof of service app with geofenced photo logs ends 'you never came' disputes. What to capture at each stop, how billing ties in, and how to roll it out.",
        keywords: "proof of service app, photo proof of delivery, GPS proof of service, field service photo app, missed pickup disputes",
        category: "Logistics & field service",
        category_slug: "logistics",
        excerpt_short: "A proof of service app with geofenced photo logs ends 'you never came' disputes. What to capture at each stop, how billing ties in, and how to roll it out.",
        excerpt_long: "\"You never came\" is one of the most expensive sentences in a service business. Without proof, you either argue, send someone back, or give a credit. A proof of service app records exactly when and where each stop was done, with a photo, so the answer is on screen in seconds.",
        read_time: "5 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Driver app taking a geotagged photo at a service stop",
        faq: [
        { q: "What if there's no signal at the stop?", a: "The app saves the photo, time and location on the phone and uploads them when signal returns." },
        { q: "Can drivers fake a photo?", a: "Photos can only be taken in the app and must be inside the geofence. That makes faking hard, and anything unusual shows up in the office view." }
        ],
        case_study_path: "/case-studies/shoreline-waste-logistics",
        integration_path: "/integrations/stripe",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "google-business-profile-hvac-job-photos",
        path: -> { blog_show_path("google-business-profile-hvac-job-photos") },
        title: "Google Business Profile posts for HVAC: turn job photos into posts automatically",
        seo_title: "Google Business Profile Posts for HVAC",
        meta_description: "How HVAC companies can turn technician job photos into Google Business Profile posts automatically, with an approval step, so local search gets fresh work.",
        keywords: "Google Business Profile for HVAC, HVAC local SEO, Google Business Profile posts automation, HVAC marketing automation, job photos to Google posts",
        category: "Home services & HVAC",
        category_slug: "home-services",
        excerpt_short: "How HVAC companies can turn technician job photos into Google Business Profile posts automatically, with an approval step, so local search gets fresh work.",
        excerpt_long: "For most HVAC companies, the Google Business Profile brings in more calls than the website. Profiles that show fresh, real work in the right towns tend to look more trustworthy to customers. The problem is time: nobody in the office has an hour a day to write posts. Here is how to turn the photos your technicians already take into Google Business Profile posts automatically.",
        read_time: "5 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "HVAC technician's job photo turned into a Google Business Profile post",
        faq: [
        { q: "Is automated posting allowed on Google Business Profile?", a: "Posting through Google's official API is allowed." },
        { q: "Do technicians need to install anything?", a: "No. They text a photo to a company number, which they already know how to do." }
        ],
        case_study_path: "/case-studies/red-dragon-hvac",
        integration_path: "/integrations/google-business-profile",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "home-service-business-automation",
        path: -> { blog_show_path("home-service-business-automation") },
        title: "Home service business automation: what to automate first",
        seo_title: "Home Service Automation: What to Automate",
        meta_description: "Home service business automation that pays back first: missed-call follow-up, booking reminders, job photos, invoices and reviews, in the order to tackle them.",
        keywords: "home service business automation, HVAC business automation, plumbing business automation, missed call text back, field service automation",
        category: "Home services & HVAC",
        category_slug: "home-services",
        excerpt_short: "Home service business automation that pays back first: missed-call follow-up, booking reminders, job photos, invoices and reviews, in the order to tackle them.",
        excerpt_long: "Home service businesses lose money in small, repeated ways: a missed call, a no-show, an invoice sent a week late. Home service business automation fixes these one at a time. Here is the order we'd tackle them in, starting with what pays back fastest.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Checklist of home service tasks in the order to automate them",
        faq: [
        { q: "Do I need to replace my field service software?", a: "Usually not. Most automation sits on top of the tools you already use, through their APIs or simple connections." },
        { q: "Will automated texts annoy customers?", a: "Not if they're useful and timed well: a confirmation, a reminder, an \"on my way\" and a receipt. Avoid marketing blasts on the same number." }
        ],
        integration_path: "/integrations/twilio",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "reso-web-api-mls-integration",
        path: -> { blog_show_path("reso-web-api-mls-integration") },
        title: "RESO Web API: how to integrate MLS data into your app",
        seo_title: "RESO Web API: How to Integrate MLS Data",
        meta_description: "How RESO Web API integration works: getting MLS access, OData queries, media and replication, rate limits, and what to plan for before you build a property app.",
        keywords: "RESO Web API integration, MLS API integration, MLS data feed developer, RESO Data Dictionary, IDX integration, real estate API developer",
        category: "Real estate",
        category_slug: "real-estate",
        excerpt_short: "How RESO Web API integration works: getting MLS access, OData queries, media and replication, rate limits, and what to plan for before you build a property app.",
        excerpt_long: "If you're building a property app, MLS data is the foundation, and the RESO Web API is how most MLSs now share it. The API is the simple part. Access agreements, data replication and the differences between MLSs take most of the effort. Here is what to plan for.",
        read_time: "7 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Listings flowing from an MLS through the RESO Web API into a property app",
        faq: [
        { q: "Is RETS still used?", a: "Some systems still run RETS feeds, but the industry has largely moved to the RESO Web API. Build new products on the Web API." },
        { q: "Do I need a broker to get MLS data?", a: "Usually, yes. Most MLSs give data access through a participating broker or a vendor agreement. Rules vary by MLS, so ask each one directly." }
        ],
        case_study_path: "/case-studies/instashowing-real-estate",
        integration_path: "/integrations/reso-mls",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "real-estate-deal-analysis-automation",
        path: -> { blog_show_path("real-estate-deal-analysis-automation") },
        title: "Real estate deal analysis automation: from an address to an offer in under 90 seconds",
        seo_title: "Real Estate Deal Analysis: Address to Offer",
        meta_description: "How real estate deal analysis software turns an address into comps, repair estimates and offer prices in under 90 seconds, with the math kept out of the AI.",
        keywords: "real estate deal analysis software, real estate deal analyzer, automated comps analysis, wholesale deal calculator, investor underwriting software",
        category: "Real estate",
        category_slug: "real-estate",
        excerpt_short: "How real estate deal analysis software turns an address into comps, repair estimates and offer prices in under 90 seconds, with the math kept out of the AI.",
        excerpt_long: "Investors who analyze every lead by hand can only look at a handful a day. Real estate deal analysis software takes an address and returns comps, a repair estimate and offer prices for each strategy, so you spend your time on the deals worth pursuing.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Deal analysis screen showing comps and offer prices for four strategies",
        faq: [
        { q: "Does the AI decide the offer price?", a: "No. The offer comes from fixed formulas and your own assumptions." },
        { q: "Can I use my own formulas and repair costs?", a: "Yes. Each strategy's formula and your repair cost assumptions should be settings you control, not hidden in the system." }
        ],
        case_study_path: "/case-studies/ai-deal-analyzer",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "stripe-connect-split-payouts-marketplace",
        path: -> { blog_show_path("stripe-connect-split-payouts-marketplace") },
        title: "Stripe Connect split payouts for marketplaces: a build guide",
        seo_title: "Stripe Connect Split Payouts for Marketplaces",
        meta_description: "How to build Stripe Connect split payments for a marketplace: account types, a ledger first, split rules, refunds and payout states that reconcile themselves.",
        keywords: "Stripe Connect split payments, marketplace payouts, Stripe Connect developer, split payment marketplace, Stripe Connect Express vs Custom",
        category: "Fintech & payments",
        category_slug: "fintech",
        excerpt_short: "How to build Stripe Connect split payments for a marketplace: account types, a ledger first, split rules, refunds and payout states that reconcile themselves.",
        excerpt_long: "Splitting one payment between several parties sounds simple until refunds, disputes and failed payouts arrive. Stripe Connect handles the regulated money movement, but your platform still has to know who is owed what at every moment. Here is how we build Stripe Connect split payments so the books balance without manual reconciliation.",
        read_time: "7 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "One customer payment split between a seller, a service provider and the platform",
        faq: [
        { q: "Express or Custom accounts?", a: "Start with Express unless you need full control over onboarding and the seller experience." },
        { q: "Do we need a money transmitter license?", a: "Stripe Connect is designed so Stripe handles the regulated money movement in many setups, but it depends on your model and countries. We're not lawyers; confirm with legal counsel before launch." }
        ],
        case_study_path: "/case-studies/vestra-payments",
        integration_path: "/integrations/stripe",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "payment-gateway-migration-guide",
        path: -> { blog_show_path("payment-gateway-migration-guide") },
        title: "Payment gateway migration without downtime or lost transactions",
        seo_title: "Payment Gateway Migration Without Downtime",
        meta_description: "A payment gateway migration plan that avoids lost transactions: token migration, running both processors in parallel, webhook mapping and reconciliation.",
        keywords: "payment gateway migration, switch payment processor, migrate to Stripe, Authorize.net to Stripe migration, card token migration",
        category: "Fintech & payments",
        category_slug: "fintech",
        excerpt_short: "A payment gateway migration plan that avoids lost transactions: token migration, running both processors in parallel, webhook mapping and reconciliation.",
        excerpt_long: "Switching payment processors is usually driven by fees, features or a processor that's holding you back. The risk is real: a failed renewal or a lost transaction costs money and trust. A payment gateway migration done in stages avoids both. Here is the plan we follow.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Payments moving from an old processor to a new one in stages",
        faq: [
        { q: "Will customers need to re-enter their cards?", a: "Usually not. If both processors support card data migration, saved cards move across securely." },
        { q: "Can we migrate subscriptions without double-charging?", a: "Yes. Recreate each subscription on the new processor with the same next billing date, cancel it on the old one at the same moment, and check both in the daily reconciliation." }
        ],
        integration_path: "/integrations/payment-gateway-migration",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "prevent-double-booking-saas",
        path: -> { blog_show_path("prevent-double-booking-saas") },
        title: "How to prevent double bookings in a SaaS booking system",
        seo_title: "How to Prevent Double Bookings in SaaS",
        meta_description: "How to prevent double booking in a SaaS booking system under burst traffic: locking, idempotent retries and separating browsing from committing a slot.",
        keywords: "prevent double booking, booking system race condition, distributed locking booking, idempotent booking API, booking platform development",
        category: "B2B SaaS",
        category_slug: "b2b-saas",
        excerpt_short: "How to prevent double booking in a SaaS booking system under burst traffic: locking, idempotent retries and separating browsing from committing a slot.",
        excerpt_long: "A double booking looks like a small bug until it happens on your busiest morning. Two customers turn up for the same tee time, class or appointment, and your client has to apologize to one of them. Here is why it happens and how to prevent double booking for good.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Two users trying to book the same slot, with only one confirmed",
        faq: [
        { q: "Is a database rule enough on its own?", a: "It stops the bad booking, but the user only learns at the final step that the slot is gone. Holds and locks give a much better experience under load." },
        { q: "What if we allow some overbooking on purpose?", a: "Model it as capacity: each slot has a limit, and a booking only succeeds while the count is under it. The same locking rules apply." }
        ],
        case_study_path: "/case-studies/golfpay360-saas",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "legacy-saas-modernization-without-downtime",
        path: -> { blog_show_path("legacy-saas-modernization-without-downtime") },
        title: "Modernize a legacy SaaS app without downtime: the strangler fig approach",
        seo_title: "Modernize a Legacy SaaS App Without Downtime",
        meta_description: "Legacy application modernization without a risky rewrite: the strangler fig approach, an edge layer, moving one feature at a time and keeping users online.",
        keywords: "legacy application modernization, strangler fig pattern, legacy SaaS rewrite, platform modernization, migrate PHP to React",
        category: "B2B SaaS",
        category_slug: "b2b-saas",
        excerpt_short: "Legacy application modernization without a risky rewrite: the strangler fig approach, an edge layer, moving one feature at a time and keeping users online.",
        excerpt_long: "When an old SaaS app starts failing under load, the instinct is to rewrite it from scratch. Big rewrites often run long, freeze new features and launch with new bugs. Legacy application modernization works better in slices: build the new system around the old one and move features across one by one while users keep working.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "New platform gradually replacing parts of a legacy app behind one edge layer",
        faq: [
        { q: "Can we keep shipping features during the migration?", a: "Yes. New features are built on the new platform, which is one of the main reasons to move in slices rather than freezing work for a full rewrite." },
        { q: "Do we have to change programming language?", a: "No. Modernization is about structure, speed and maintainability. Sometimes the right move is a cleaner version of the same stack." }
        ],
        case_study_path: "/case-studies/word-of-mouth-modernization",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "fhir-ehr-integration-guide",
        path: -> { blog_show_path("fhir-ehr-integration-guide") },
        title: "FHIR EHR integration: a practical guide for healthtech teams",
        seo_title: "FHIR EHR Integration: A Practical Guide",
        meta_description: "A practical guide to FHIR EHR integration for healthtech teams: which resources you need, sandbox access, auth, sync rules and what breaks in production.",
        keywords: "FHIR EHR integration, FHIR API integration, SMART on FHIR, EHR integration developer, athenahealth FHIR integration, HL7 FHIR R4",
        category: "Healthcare & EHR",
        category_slug: "healthcare",
        excerpt_short: "A practical guide to FHIR EHR integration for healthtech teams: which resources you need, sandbox access, auth, sync rules and what breaks in production.",
        excerpt_long: "FHIR EHR integration is now the standard way for new healthcare apps to read and write patient records. The standard is the easy part. The hard parts are getting access, deciding who owns each record, and keeping two systems in sync when real patients and staff use both. This guide covers what we plan for on every integration.",
        read_time: "7 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Diagram of an app syncing appointments and notes with an EHR through FHIR",
        faq: [
        { q: "Is FHIR the same in every EHR?", a: "The core resources are the same, but supported resources, write permissions, extensions and the approval process differ by vendor." },
        { q: "Do I need FHIR, or can I use the EHR's own API?", a: "Use FHIR where it covers what you need, because it carries over to other EHRs. Use the vendor's own API for gaps, such as some scheduling actions FHIR doesn't support." }
        ],
        case_study_path: "/case-studies/medical-voice-ai",
        integration_path: "/integrations/fhir-ehr",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      {
        slug: "hipaa-ready-software-vendor-questions",
        path: -> { blog_show_path("hipaa-ready-software-vendor-questions") },
        title: "HIPAA-ready software: the questions to ask a development vendor",
        seo_title: "HIPAA-Ready Software: Questions to Ask",
        meta_description: "Building software that touches patient data? The questions to ask a development vendor about BAAs, PHI flow, audit logs and access before you sign anything.",
        keywords: "HIPAA-ready software development, HIPAA software development company, PHI data handling, BAA software vendor, healthcare app security checklist",
        category: "Healthcare & EHR",
        category_slug: "healthcare",
        excerpt_short: "Building software that touches patient data? The questions to ask a development vendor about BAAs, PHI flow, audit logs and access before you sign anything.",
        excerpt_long: "If your software will store or process patient data, the team that builds it shapes your risk for years. Many vendors say \"HIPAA compliant\". Few can explain where patient data actually goes. These are the questions we would want a client to ask us, grouped by topic.",
        read_time: "6 min",
        date: "26 Nov 2026", date_iso: "2026-11-26",
        image: "blogs/astechware_new_web_blog_2.webp",
        image_alt: "Checklist of HIPAA-ready software questions next to a data flow diagram",
        faq: [
        { q: "Can we use ChatGPT or Claude with patient data?", a: "Only through a business plan or API where the provider signs a BAA, and only with the data you actually need." },
        { q: "Do we need a HIPAA certification?", a: "There is no official HIPAA certification for software. Some vendors hold security audits such as SOC 2, which are separate. Ask what an audit covered rather than relying on a badge." }
        ],
        case_study_path: "/case-studies/medical-voice-ai",
        author_name: "Ahmad Kamran", author_title: "Founder, A'sTechware"
      },
      # Expert AI series (production-first, what agencies miss)
      { slug: "ai-chatbot-death-spiral", path: -> { blog_show_path("ai-chatbot-death-spiral") }, title: "Why AI Chatbots Fail After Launch", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Your AI chatbot launched at 95% accuracy. Two months later, customers are complaining. Why chatbots degrade and how to fix it with continuous improvement.", excerpt_long: "Agencies demo with curated data and have no plan for accuracy degradation. In production, user language evolves, edge cases accumulate, and model drift goes unnoticed until customers complain. We break down the chatbot death spiral—Week 1: 95% → Week 8: 60%—and the monitoring, feedback loops, and retraining strategies that actually keep production chatbots reliable.", read_time: "11 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/repi-work.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "ai-cost-explosion", path: -> { blog_show_path("ai-cost-explosion") }, title: "How to Cut Runaway AI Costs", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI feature costs $50K/month. It should cost $8K. Smart model routing, caching, and token optimization without sacrificing quality.", excerpt_long: "Using GPT-4 for everything, no caching, and inefficient prompts burn budgets fast. We cover cost attribution, model tiering, semantic caching, prompt compression, and the math that gets legal tech from $40K to $16K—with real strategies you can apply this week.", read_time: "10 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "prompt-injection-security", path: -> { blog_show_path("prompt-injection-security") }, title: "Prompt Injection: How to Protect Your AI", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "Your AI agent just emailed your entire customer database to an attacker. What prompt injection is and defense-in-depth that works.", excerpt_long: "Adversarial inputs, no output filtering, and agents with too many permissions create real incidents. We walk through types of prompt injection, input sanitization and output validation that work, privilege separation for agents, and how to red-team your own AI before someone else does.", read_time: "12 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/3agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "rag-implementation-mistakes", path: -> { blog_show_path("rag-implementation-mistakes") }, title: "RAG Mistakes That Kill Accuracy", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You gave your AI access to all your docs. It still makes things up. Bad chunking, wrong embeddings, and no re-ranking—and how to fix them.", excerpt_long: "Naive chunking, bad embeddings, and no confidence filtering lead to hallucinations despite 'having the data.' We cover chunking that preserves meaning, hybrid search, re-ranking with cross-encoders, and prompt engineering for RAG—plus when to use fine-tuning instead.", read_time: "11 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/turbo_astechware.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "agentic-ai-governance", path: -> { blog_show_path("agentic-ai-governance") }, title: "AI Agents Need Permissions and Approvals", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "Your AI agent just deleted 10,000 records because a user said 'clean this up.' Scoped permissions, approval workflows, and audit trails that scale.", excerpt_long: "Agents with too many permissions and no approval workflows cause real damage. We outline the governance framework: scoped permissions, human-in-the-loop for critical actions, dry-run mode, confidence thresholds, rate limiting, audit logging, rollback, and testing for adversarial scenarios—with SOC 2 and HIPAA in mind.", read_time: "12 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/whatsapp-agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "fine-tuning-vs-prompting", path: -> { blog_show_path("fine-tuning-vs-prompting") }, title: "Fine-Tuning vs Prompting: When Each Wins", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your legal AI costs $15K/month in API calls. A $80K fine-tuned model could pay for itself in 6 months. When and how to decide.", excerpt_long: "When prompting is enough versus when fine-tuning wins—domain-specific language, volume, accuracy plateaus, and cost. We include the ROI calculation, data requirements, LoRA vs full fine-tuning, and real examples: customer support, medical coding, and legal contract analysis with 10x cost reduction.", read_time: "10 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/astechware_new_web_blog_2.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "context-window-lost-in-middle", path: -> { blog_show_path("context-window-lost-in-middle") }, title: "Why Long Context Windows Miss Information", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You have a 128K context window. Your AI still misses key info in the middle. The lost-in-the-middle problem and when RAG beats long context.", excerpt_long: "LLMs attend to start and end of context and underperform on the middle. We cover the research, when long context helps versus when RAG is better, the hybrid approach, and best practices for structuring prompts and retrieval so critical information isn't lost.", read_time: "10 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/startup_post_astechware.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "multimodal-ai-pitfalls", path: -> { blog_show_path("multimodal-ai-pitfalls") }, title: "Vision AI for Documents: What Goes Wrong", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI can 'see' images. So why does it keep missing the invoice total? Preprocessing, OCR-first pipelines, and structured output.", excerpt_long: "Wrong resolution, no fallback when vision fails, and ignoring token costs for images. We cover image preprocessing, when to use OCR then LLM, structured output prompting, and real pipelines for invoice processing, ID verification, and medical imaging—with cost and accuracy in mind.", read_time: "11 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/repi-work.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "synthetic-data-trap", path: -> { blog_show_path("synthetic-data-trap") }, title: "The Synthetic Data Trap in AI Training", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You trained your model on AI-generated data. Now it's worse. Model collapse, when synthetic data helps, and mixing strategies that work.", excerpt_long: "Synthetic data promises scale and privacy but model collapse is real—training on AI output degrades models. We cover when synthetic data works (augmentation, rare cases) versus when it fails, mix ratios, validation, and real case studies from customer support and image generation.", read_time: "10 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "testing-ai-systems", path: -> { blog_show_path("testing-ai-systems") }, title: "How to Test AI Systems Before Launch", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI passed all tests. Then it told a customer to 'go away.' Non-determinism, adversarial testing, and production monitoring as testing.", excerpt_long: "Traditional unit tests don't catch AI failures. We outline the AI testing framework: prompt regression testing, adversarial and jailbreak testing, evaluation metrics that matter, A/B testing in production, human evaluation, and monitoring as ongoing testing—with examples and tools.", read_time: "11 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/3agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      # Buyer guides & how-to (SEO: best AI agent company, fractional engineering, LangGraph, HIPAA, support automation, production AI)
      { slug: "how-to-evaluate-ai-agent-development-company-2026", path: -> { blog_show_path("how-to-evaluate-ai-agent-development-company-2026") }, title: "How to Choose an AI Development Company", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Choosing the right AI agent development partner: production track record, governance, and what separates the best AI agent companies from demo shops.", excerpt_long: "Not all AI agent companies ship production systems. We break down how to evaluate vendors: proof of production deployments, governance and human-in-the-loop, cost and scaling behavior, and red flags that signal prototype-only teams. A practical checklist for finding the best AI agent company for your use case.", read_time: "9 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "ahmad/repi-work.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "what-to-look-for-hiring-fractional-engineering-team", path: -> { blog_show_path("what-to-look-for-hiring-fractional-engineering-team") }, title: "Hiring a Fractional Engineering Team", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Fractional engineering teams extend your capacity without full-time hires. What to look for: ownership, communication, and production outcomes.", excerpt_long: "A great fractional engineering team acts as an extension of your team—same standards, clear ownership, and production-ready output. We cover what to look for when hiring: scope and milestones, communication cadence, tech stack fit, and how to tell if they ship or just advise. Plus red flags and how to structure the engagement for success.", read_time: "8 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "blogs/astechware_new_web_blog_2.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "building-production-ai-agents-langgraph-complete-guide", path: -> { blog_show_path("building-production-ai-agents-langgraph-complete-guide") }, title: "Building Production AI Agents With LangGraph", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "LangGraph development for real agents: state graphs, checkpoints, human-in-the-loop, and shipping beyond the tutorial.", excerpt_long: "LangGraph gives you stateful, multi-step agent workflows with cycles and branching—but tutorials stop at the happy path. We cover production LangGraph development: designing state graphs, checkpointing and persistence, error handling and retries, human-in-the-loop nodes, observability, and how we use it for support and triage agents that run in production.", read_time: "12 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "blogs/turbo_astechware.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "hipaa-compliant-ai-healthcare-companies-guide", path: -> { blog_show_path("hipaa-compliant-ai-healthcare-companies-guide") }, title: "HIPAA and AI: A Guide for Healthcare Teams", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "HIPAA AI software requirements: BAA, minimum necessary, audit trails, and how to build AI that fits healthcare compliance.", excerpt_long: "Using AI on PHI means HIPAA applies. We outline what healthcare companies need for HIPAA-ready AI: BAAs with vendors, minimum necessary access, encryption and access controls, audit logging, and how to design agents and RAG so they don't leak or misuse PHI. Practical steps and common gaps that trigger findings.", read_time: "11 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "ahmad/whatsapp-agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "reduced-customer-support-tickets-90-percent-ai-agents", path: -> { blog_show_path("reduced-customer-support-tickets-90-percent-ai-agents") }, title: "How AI Agents Cut Support Tickets", category: "Case Studies", category_slug: "case-studies", excerpt_short: "AI customer support automation that actually reduces tickets: triage, deflection, and human handoff that scales.", excerpt_long: "We deployed AI agents for customer support that handle FAQs, triage, and escalation—reducing inbound tickets for one client. This case study covers the architecture: knowledge base, confidence thresholds, when to deflect vs escalate, and how we measured impact. What it takes to replicate AI customer support automation that doesn't frustrate users.", read_time: "9 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "ahmad/3agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "production-ai-vs-prototype-ai-why-projects-fail", path: -> { blog_show_path("production-ai-vs-prototype-ai-why-projects-fail") }, title: "Why Most AI Projects Never Reach Production", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Production AI development is different from demos. Why most AI projects fail—and what it takes to ship systems that last.", excerpt_long: "Demos look great; production breaks. We explain the gap between prototype AI and production AI: reliability, cost at scale, governance, and maintenance. Why most AI projects fail after the pilot, and what production AI development actually requires—monitoring, human-in-the-loop, and treating AI as a product, not a one-off experiment.", read_time: "10 min", date: "Feb 27, 2026", date_iso: "2026-02-27", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "Ahmad Kamran", author_title: "Founder" },
      # Case studies & existing posts
      { slug: "modular-ai-agents-case-study", path: -> { blog_show_path("modular-ai-agents-case-study") }, title: "Modular AI Agents for Support and Outreach", category: "Case Studies", category_slug: "case-studies", excerpt_short: "Production-ready AI agents for support, voice, and sales outreach—built to plug into your stack with human handoff and full customization.", excerpt_long: "While tools like ChatGPT and Dialogflow excel at demos, real teams need AI that integrates into their tech stack, customizes for support and outreach flows, and maintains human handoff. A'sTechware built modular, production-ready agents for WhatsApp support, voice calls, and cold email that plug into any system and have been battle-tested across healthcare, real estate, and SaaS.", read_time: "8 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/repi-work.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      # vestra-app-case-study redirects to /case-studies/vestra-payments (same project)
      { slug: "whatsapp-voice-ai-agent-demo", path: -> { blog_show_path("whatsapp-voice-ai-agent-demo") }, title: "WhatsApp & Voice AI for Appointment Booking", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Real-time AI agents for WhatsApp and voice that triage, book appointments, and escalate to humans when needed.", excerpt_long: "Healthcare and service businesses need 24/7 responsiveness without burning out staff. We built demo-ready AI agents for WhatsApp and voice that handle triage, appointment booking, and intelligent escalation—with human-in-the-loop so nothing falls through the cracks.", read_time: "5 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "ahmad/whatsapp-agent.jpeg", author_name: "Ahmad Kamran", author_title: "Founder" },
      { slug: "a-laymans-guide-for-hiring-a-top-software-company-in-pakistan", path: -> { blog_show_path("a-laymans-guide-for-hiring-a-top-software-company-in-pakistan") }, title: "How to Hire a Software Company in Pakistan", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Practical advice for non-technical founders on evaluating and selecting a software partner that can deliver.", excerpt_long: "Hiring the right software company is critical for product success. This guide walks through how to evaluate technical partners, what to look for in proposals and teams, and how to avoid common pitfalls when outsourcing development.", read_time: "8 min", date: "Feb 16, 2026", date_iso: "2026-02-16", image: "blogs/top_software_company.webp", author_name: "Ahmad Kamran", author_title: "Founder" }
    ].map { |article| with_blog_category(article) }
  end

  def with_blog_category(article)
    slug = article[:category_slug].to_s
    return article if BLOG_CATEGORIES.key?(slug) && slug != "general" && !HEALTHCARE_BLOG_SLUGS.include?(article[:slug])

    assigned = HEALTHCARE_BLOG_SLUGS.include?(article[:slug]) ? "healthcare" : (BLOG_CATEGORIES.key?(slug) ? slug : "general")
    assigned = "healthcare" if HEALTHCARE_BLOG_SLUGS.include?(article[:slug])
    assigned = "general" unless BLOG_CATEGORIES.key?(slug) || assigned == "healthcare"
    cat = BLOG_CATEGORIES.fetch(assigned)
    article.merge(category: cat[:name], category_slug: assigned)
  end

  def blog_category(slug)
    BLOG_CATEGORIES[slug.to_s]
  end

  def blog_categories_with_posts
    used = blog_articles_list.map { |article| article[:category_slug].to_s }.uniq
    BLOG_CATEGORIES.select { |slug, _| used.include?(slug) }
  end

  def blog_articles_for_category(category_slug)
    blog_articles_list.select { |article| article[:category_slug].to_s == category_slug.to_s }
  end

  def blog_related_guides(article, limit: 3)
    return [] if article.blank?

    same = blog_articles_for_category(article[:category_slug]).reject { |item| item[:slug] == article[:slug] }
    pool = same.presence || blog_articles_for_category("general").reject { |item| item[:slug] == article[:slug] }
    pool.first(limit)
  end

  def blog_published_label(article)
    iso = article[:date_iso].presence
    return article[:date].to_s if iso.blank?

    date = Date.iso8601(iso) rescue nil
    return article[:date].to_s if date.blank?

    "Published #{date.strftime('%-d %b %Y')}"
  end

  def blog_updated_label(article)
    updated = article[:updated_iso].presence
    published = article[:date_iso].presence
    return nil if updated.blank? || updated == published

    date = Date.iso8601(updated) rescue nil
    return nil if date.blank?

    "Updated #{date.strftime('%-d %b %Y')}"
  end

  def blog_featured_article
    blog_index_articles.first || blog_articles_list.first
  end

  def blog_index_articles
    list = blog_articles_list
    if params[:category].present?
      list = list.select { |article| article[:category_slug].to_s == params[:category].to_s }
    end
    if params[:q].present?
      query = params[:q].to_s.downcase
      list = list.select do |article|
        article[:title].to_s.downcase.include?(query) || article[:excerpt_short].to_s.downcase.include?(query)
      end
    end
    list
  end

  # Eight offerings shown on homepage "What we build" and /services hub (same order).
  def what_we_build_list
    [
      {
        title: "Web apps",
        description: "Customer portals, dashboards, internal tools and SaaS platforms.",
        icon: "fa-desktop",
        path: :custom_software_path
      },
      {
        title: "Mobile apps",
        description: "iOS and Android apps for your customers or your field team.",
        icon: "fa-mobile",
        path: :custom_software_path
      },
      {
        title: "AI & automation",
        description: "AI agents and workflows that read documents, answer calls and remove manual work.",
        icon: "fa-cogs",
        path: :ai_agent_development_path
      },
      {
        title: "MVP development",
        description: "Take a new product from idea to launch, in milestones.",
        icon: "fa-rocket",
        path: :mvp_development_path
      },
      {
        title: "Integrations & APIs",
        description: "Connect the tools you already use so data flows without retyping.",
        icon: "fa-plug",
        path: :api_integrations_path
      },
      {
        title: "Platform modernization",
        description: "Fix slow or fragile systems and modernize them without downtime.",
        icon: "fa-refresh",
        path: :platform_modernization_path
      },
      {
        title: "DevOps, cloud & security",
        description: "Cloud setup, CI/CD, monitoring, and security reviews and hardening.",
        icon: "fa-cloud",
        path: :devops_engineering_path
      },
      {
        title: "Dedicated engineers",
        description: "Add AI, web or mobile engineers to your team, backed by ours.",
        icon: "fa-users",
        path: :hire_dedicated_developers_path
      }
    ]
  end

  def who_we_work_with_list
    [
      {
        title: "Startups and founders",
        description: "From first MVP to a product that scales.",
        icon: "fa-lightbulb-o"
      },
      {
        title: "SaaS companies",
        description: "New features, AI and rebuilds for products with real customers.",
        icon: "fa-cubes"
      },
      {
        title: "Growing businesses",
        description: "Software and automation that remove manual work from daily operations.",
        icon: "fa-line-chart"
      },
      {
        title: "Agencies",
        description: "White-label development under your brand and NDA.",
        icon: "fa-handshake-o"
      }
    ]
  end

  # Eight tool cards for homepage and /services. Same tools, regrouped so cards stay even.
  def tools_platforms_groups
    [
      {
        title: "AI & machine learning",
        icon: "fa-magic",
        tools: ["OpenAI", "Anthropic (Claude)", "Google Gemini", "LangChain", "Deepgram", "ElevenLabs"]
      },
      {
        title: "Payments & finance",
        icon: "fa-credit-card",
        tools: ["Stripe", "Stripe Connect", "Plaid", "Square", "Clover", "PayPal", "Authorize.net", "Dwolla", "QuickBooks Online"]
      },
      {
        title: "Communication",
        icon: "fa-comments",
        tools: ["Twilio", "Mailgun", "Microsoft 365 / Outlook", "Google Workspace"]
      },
      {
        title: "Business & industry apps",
        icon: "fa-briefcase",
        tools: ["DocuSign", "Google Business Profile", "Meta", "athenahealth (FHIR)", "RESO / MLS", "ATTOM", "Make.com"]
      },
      {
        title: "Cloud & DevOps",
        icon: "fa-cloud",
        tools: ["AWS", "Google Cloud", "Microsoft Azure", "DigitalOcean", "Cloudflare", "Docker", "GitHub Actions"]
      },
      {
        title: "Web",
        icon: "fa-code",
        tools: ["React", "Next.js", "Node.js", "NestJS", "Python / FastAPI", "Ruby on Rails", "Java / Spring Boot", "Vue.js"]
      },
      {
        title: "Mobile & maps",
        icon: "fa-mobile",
        tools: ["React Native", "Flutter", "Google Maps", "PostGIS"]
      },
      {
        title: "Data & search",
        icon: "fa-database",
        tools: ["PostgreSQL", "Redis", "MongoDB", "DynamoDB", "Elasticsearch", "Meilisearch"]
      }
    ]
  end

  alias_method :core_services_list, :what_we_build_list

  # BreadcrumbList JSON-LD for inner pages (services, solutions, about, contact, etc.)
  def breadcrumb_list_json_ld
    base = Rails.env.production? ? "https://astechware.com" : base_url
    path = request.path.to_s.sub(/\?.*\z/, "").strip
    path = path.sub(/\/*\z/, "").presence || "/"
    segments = path.split("/").reject(&:blank?)
    items = [{ "@type" => "ListItem", "position" => 1, "name" => "Home", "item" => base + "/" }]
    segments.each_with_index do |seg, i|
      current_path = "/" + segments[0..i].join("/")
      name = breadcrumb_segment_name(seg, segments, i)
      items << { "@type" => "ListItem", "position" => i + 2, "name" => name, "item" => base + current_path }
    end
    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }.to_json
  end

  def breadcrumb_segment_name(segment, all_segments, index)
    names = {
      "about" => "About",
      "contact" => "Contact",
      "case-studies" => "Case Studies",
      "methodology" => "Methodology",
      "how-we-derisk-projects" => "How We De-Risk Projects",
      "blogs" => "Blog",
      "services" => "Services",
      "solutions" => "Solutions",
      "ai-agent-development" => "AI Agent Development",
      "machine-learning" => "Machine Learning",
      "platform-modernization" => "Platform Modernization",
      "custom-software" => "Custom Software, Web & Mobile",
      "mvp-development" => "MVP Development",
      "api-integrations" => "API & Integrations",
      "integrations" => "Integrations",
      "devops-engineering" => "DevOps Engineering",
      "ai-agents" => "AI Agents",
      "healthcare" => "Healthcare",
      "legal" => "Legal",
      "financial" => "Financial",
      "b2b-saas" => "B2B SaaS",
      "professional-services" => "Professional Services",
      "education-technology" => "Education Technology",
      "privacy-policy" => "Privacy Policy",
      "terms-of-service" => "Terms of Service"
    }
    if index.positive? && all_segments[index - 1] == "integrations" && defined?(IntegrationCatalog)
      entry = IntegrationCatalog.find(segment)
      return entry[:title] if entry.present?
    end

    names[segment] || segment.humanize
  end

  # Find blog article hash by slug (for blogs#show). Returns nil if not found.
  def blog_article_by_slug(slug)
    return nil if slug.blank?
    blog_articles_list.find { |a| a[:slug].to_s == slug.to_s }
  end

  # Find blog article hash by path (e.g. for current post page). Returns nil if not found.
  def blog_article_for_path(path)
    return nil if path.blank?
    path_str = path.is_a?(String) ? path : url_for(path)
    norm = path_str.to_s.sub(/\Ahttps?:\/\/[^\/]+/, "").split("?").first
    blog_articles_list.find { |a| a[:path].call.to_s.sub(/\Ahttps?:\/\/[^\/]+/, "").split("?").first == norm }
  end

  # Related articles (exclude current path), max 4
  def blog_related_articles(current_path, limit: 4)
    current_str = current_path.is_a?(String) ? current_path : url_for(current_path)
    norm = current_str.to_s.sub(/\Ahttps?:\/\/[^\/]+/, "").split("?").first
    blog_articles_list.reject { |a| a[:path].call.to_s.sub(/\Ahttps?:\/\/[^\/]+/, "").split("?").first == norm }.first(limit)
  end

  # Per-slug SEO keywords for blog posts
  def blog_seo_keywords(slug)
    keywords_by_slug = {
      "what-to-look-for-hiring-fractional-engineering-team" => "fractional engineering team, hire software engineers, dedicated developers, engineering partner, extended engineering team",
      "a-laymans-guide-for-hiring-a-top-software-company-in-pakistan" => "hire software development partner, outsourcing engineering team, top software company, software engineering partner",
      "how-to-evaluate-ai-agent-development-company-2026" => "AI development company, AI engineering partner, production AI, best AI agent company, AI agent development partner",
      "hipaa-compliant-ai-healthcare-companies-guide" => "healthcare AI engineering partner, HIPAA-ready AI, hire healthcare software engineers, healthcare AI automation",
      "building-production-ai-agents-langgraph-complete-guide" => "LangGraph development, production AI agents, AI automation systems, workflow automation, AI engineering partner",
      "reduced-customer-support-tickets-90-percent-ai-agents" => "AI customer support automation, workflow automation, AI agents, support ticket automation",
      "production-ai-vs-prototype-ai-why-projects-fail" => "production AI development, AI engineering partner, workflow automation, custom automation software",
      "modular-ai-agents-case-study" => "AI automation, modular AI agents, workflow automation, healthcare AI, real estate automation",
      "vestra-app-case-study" => "real estate software, property management automation, real estate operations software",
      "whatsapp-voice-ai-agent-demo" => "healthcare AI, voice AI automation, AI agents, HIPAA-ready AI"
    }
    keywords_by_slug[slug.to_s] || "A'sTechware, production AI, platform engineering, AI engineering partner, workflow automation, custom software development"
  end

  # Per-slug SEO description override for blog posts (falls back to excerpt_short)
  def blog_seo_description(article)
    return article[:meta_description] if article[:meta_description].present?

    slug = article[:slug].to_s
    descriptions = {
      "what-to-look-for-hiring-fractional-engineering-team" => "What to look for when hiring a fractional engineering team: ownership, communication, production outcomes, and how to structure the engagement.",
      "a-laymans-guide-for-hiring-a-top-software-company-in-pakistan" => "A practical guide for hiring a top software development partner: evaluating technical teams, proposals, and avoiding common outsourcing pitfalls.",
      "how-to-evaluate-ai-agent-development-company-2026" => "How to evaluate an AI agent development company in 2026: production track record, governance, cost at scale, and the red flags to avoid before you hire.",
      "hipaa-compliant-ai-healthcare-companies-guide" => "HIPAA-ready AI guide for healthcare teams: BAA requirements, PHI handling, audit trails, and building AI that fits healthcare rules without shortcuts.",
      "building-production-ai-agents-langgraph-complete-guide" => "Complete guide to building production AI agents with LangGraph: state graphs, checkpoints, human-in-the-loop, and shipping beyond tutorials.",
      "ai-cost-explosion" => "Your AI feature costs too much to run. Smart model routing, caching and token optimization that cut spend without sacrificing answer quality in production.",
      "prompt-injection-security" => "What prompt injection is, how attackers abuse agents, and defense-in-depth that works: input checks, output filters and least-privilege tool access.",
      "rag-implementation-mistakes" => "You gave your AI access to all your docs and it still makes things up. Bad chunking, wrong embeddings, missing re-ranking, and how to fix each one.",
      "fine-tuning-vs-prompting" => "When prompting is enough and when fine-tuning wins for domain AI: cost, accuracy plateaus, data needs, and a practical way to decide for your stack.",
      "multimodal-ai-pitfalls" => "Why vision models miss invoice totals and form fields: preprocessing, OCR-first pipelines, structured output, and when not to send raw images.",
      "synthetic-data-trap" => "You trained on AI-generated data and quality got worse. Model collapse explained, when synthetic data helps, and mix strategies that actually work.",
      "testing-ai-systems" => "Your AI passed every test, then failed with a customer. Non-determinism, adversarial testing, and production monitoring treated as ongoing testing.",
      "reduced-customer-support-tickets-90-percent-ai-agents" => "AI customer support automation that actually reduces tickets: triage, deflection and human handoff, with confidence thresholds that keep users happy.",
      "production-ai-vs-prototype-ai-why-projects-fail" => "Production AI development is different from demos. Why most AI projects fail after the pilot, and what it takes to ship systems that last in ops.",
      "modular-ai-agents-case-study" => "Production-ready AI agents for support, voice and sales outreach, built to plug into your stack with human handoff and full customization options.",
      "whatsapp-voice-ai-agent-demo" => "Real-time AI agents for WhatsApp and voice that triage, book appointments and escalate to humans when needed, with guardrails for service teams."
    }
    text = descriptions[slug].presence || article[:excerpt_short].to_s
    text = text.truncate(165)
    text
  end

  # Single Organization JSON-LD for the whole site (rendered once in the layout).
  def organization_json_ld
    base = Rails.env.production? ? "https://astechware.com" : base_url
    logo_url = seo_og_image_url
    {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "@id" => "https://astechware.com/#organization",
      "name" => "A'sTechware",
      # [[AHMAD: exact registered name, e.g. "Astechware LLC"]] — keep AsTechware LLC until confirmed
      "legalName" => "AsTechware LLC",
      "url" => base,
      "logo" => logo_url.present? ? { "@type" => "ImageObject", "url" => logo_url } : nil,
      "description" => "AsTechware LLC (Wyoming, USA) with an engineering team in Lahore, Pakistan, serving legal, healthcare, construction and logistics teams in the US, UK, Canada and Australia.",
      "email" => "ahmad@astechware.com",
      "foundingDate" => "2022",
      "numberOfEmployees" => {
        "@type" => "QuantitativeValue",
        "minValue" => 20,
        "maxValue" => 25
      },
      "founder" => {
        "@type" => "Person",
        "name" => "Ahmad Kamran",
        "jobTitle" => "Founder & CEO",
        "url" => "#{base}/about",
        "sameAs" => [
          "https://www.linkedin.com/in/engr-ahmad-kamran",
          "https://www.upwork.com/freelancers/ahmadkamrans",
          "https://www.upwork.com/freelancers/~01eb09bb74c3e6d04b",
          "https://www.youtube.com/@ahmadkamran518"
        ]
      },
      "sameAs" => [
        "https://www.linkedin.com/company/astechware",
        "https://www.youtube.com/@ahmadkamran518",
        "https://clutch.co/profile/astechware"
      ],
      "areaServed" => ["United States", "United Kingdom", "Canada", "Australia"],
      "address" => {
        "@type" => "PostalAddress",
        "addressRegion" => "WY",
        "addressCountry" => "US"
      },
      "contactPoint" => {
        "@type" => "ContactPoint",
        "email" => "ahmad@astechware.com",
        "contactType" => "sales",
        "url" => "#{base}/contact"
      }
    }.compact
  end

  # JSON-LD for case study detail pages
  def case_study_article_json_ld(seo)
    base = Rails.env.production? ? "https://astechware.com" : base_url
    slug = seo[:slug].to_s
    org_ref = { "@id" => "https://astechware.com/#organization" }
    {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => seo[:title],
      "description" => seo[:description],
      "keywords" => seo[:keywords],
      "url" => "#{base}/case-studies/#{slug}",
      "image" => seo_og_image_url,
      # [[AHMAD: case study date_iso for each slug]] — omit dates until confirmed
      "datePublished" => seo[:date_iso].presence,
      "dateModified" => seo[:date_iso].presence,
      "author" => org_ref,
      "publisher" => org_ref,
      "about" => seo[:keywords].to_s.split(",").first(3).map(&:strip)
    }.compact
  end

  HIRE_ENGINEER_FAQ = [
    {
      q: "How fast can someone start?",
      a: "We match on skills and time zone overlap first, then run a one-week paid trial before month-to-month engagement. Typical start after agreement is within one to two weeks."
    },
    {
      q: "What if the engineer is not a fit?",
      a: "After the one-week paid trial, we replace the engineer at no extra cost if it is not working. Month-to-month terms mean you can scale down without penalty when priorities change."
    },
    {
      q: "What tools and workflows do you use?",
      a: "Your stack, your rituals. We work in your Slack, Jira, GitHub, or GitLab, join your standups, and follow your branching and review rules. Our seniors review behind the scenes; you manage day to day."
    },
    {
      q: "Is this a freelancer marketplace?",
      a: "No. You get a full-time dedicated engineer embedded in your team, not hourly gig workers. The same person shows up daily, with our senior team behind them for review and cover during leave."
    },
    {
      q: "Do you offer white-label for agencies?",
      a: "Yes. Agencies can place engineers under their brand with NDAs in place. The engineer works in the agency or end-client tools, and we stay invisible to the end client when that is what you need."
    }
  ].freeze

  def hire_faq_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => HIRE_ENGINEER_FAQ.map { |item|
        {
          "@type" => "Question",
          "name" => item[:q],
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => item[:a].to_s.gsub(/\[\[AHMAD:[^\]]*\]\]/, "").squeeze(" ").strip
          }
        }
      }
    }
  end

  def related_links_for_current_page
    RelatedLinks.for_path(request.path)
  end

  def resolve_related_link_path(path)
    case path
    when Symbol
      unless route_helper_defined?(path)
        log_skipped_related_link(path)
        return nil
      end

      public_send(path)
    when String
      path
    when Proc
      instance_exec(&path)
    end
  rescue ActionController::UrlGenerationError, NoMethodError => e
    log_skipped_related_link(path, e.message)
    nil
  end

  def resolved_related_links(links)
    Array(links).filter_map do |entry|
      href = resolve_related_link_path(entry[:path])
      next if href.blank?

      entry.merge(href: href)
    end
  end

  def log_skipped_related_link(path, message = nil)
    return unless Rails.env.development?

    detail = path.is_a?(Symbol) ? "route helper #{path}" : path.inspect
    Rails.logger.info("[RelatedLinks] Skipped link (#{detail}#{message ? ": #{message}" : ""})")
  end
end
