# frozen_string_literal: true

# Single source of truth for case study SEO metadata and slugs.
# Used by HomeController#case_study and SitemapController.
class CaseStudyCatalog
  CATALOG = {
    "medical-voice-ai" => {
      title: "HIPAA Voice Booking & AI Scribe for Clinics",
      description: "How we built HIPAA-ready voice booking and an AI scribe for a private clinic group: PHI never reaches the LLM, FHIR sync, provider approval.",
      keywords: "healthcare AI, HIPAA-ready AI, medical voice automation, AI medical scribe, voice AI healthcare, private clinic software, case study",
      quote_name: nil
    },
    "flss-legal-process-serving" => {
      title: "Process Serving Software Platform",
      description: "How we built a process serving platform that holds up in court: multi-tenant isolation, GPS evidence, affidavits, and human-approved AI intake.",
      keywords: "process serving software, legal operations automation, process serving SaaS, legal software engineering, case study",
      quote_name: nil
    },
    "ai-deal-analyzer" => {
      title: "AI Real Estate Deal Analyzer",
      description: "How we built an AI deal analyzer from property address to offer price in minutes: deterministic Python numbers plus a Claude explanation layer.",
      keywords: "real estate AI, investment analysis automation, real estate software, property analysis automation, case study",
      quote_name: nil
    },
    "shoreline-waste-logistics" => {
      title: "Route & Proof-of-Service Platform",
      description: "How we built route planning and proof-of-service for Shoreline Waste: dispatch, geospatial routing, and completion evidence for hauling ops.",
      keywords: "logistics automation, trucking dispatch software, route optimization, fleet management, waste logistics, case study",
      quote_name: "Zach Marion"
    },
    "vestra-payments" => {
      title: "Marketplace Split Payments Platform",
      description: "How we built automated split payouts for a PropTech marketplace: ledger-first accounting, Stripe Connect, and idempotent settlement.",
      keywords: "marketplace payments, split payouts, Stripe Connect, payment settlement, fintech engineering, case study",
      quote_name: "Nathan"
    },
    "zofi-cash-fintech" => {
      title: "Earned Wage Access App",
      description: "How we built an earned wage access app with automated repayment: real-time accruals, safe-to-withdraw limits, and payroll settlement files.",
      keywords: "earned wage access, payroll settlement automation, fintech software development, case study",
      quote_name: nil
    },
    "golfpay360-saas" => {
      title: "Golf Booking & Payments Platform",
      description: "How we built tee-time booking and payments for golf courses: high-concurrency booking, Stripe Terminal, and Clover and Square POS.",
      keywords: "golf booking software, tee time booking, Stripe Terminal, POS integration, multi-tenant SaaS, case study",
      quote_name: "Dale Merritt"
    },
    "red-dragon-hvac" => {
      title: "HVAC Marketing Automation",
      description: "How we turned HVAC job photos into Google posts: field proof capture, manager approval, and local SEO publishing for a home services team.",
      keywords: "HVAC marketing automation, field service software, local SEO automation, Google Business Profile, case study",
      quote_name: nil
    },
    "eventvesta-ai-marketing" => {
      title: "AI Marketing Workflow Platform",
      description: "How we built AI drafts for posts and ads with approvals for an events marketing team: Meta and Google campaigns with guardrails.",
      keywords: "AI marketing automation, event marketing software, workflow automation, Meta ads automation, case study",
      quote_name: nil
    },
    "instashowing-real-estate" => {
      title: "Real Estate Showing & Offer Platform",
      description: "How we built showing scheduling and offer management for real estate agents: availability, coordination, and offer document workflows.",
      keywords: "real estate software, property showing automation, offer management, real estate operations, case study",
      quote_name: "Joseph Chiavatti"
    },
    "word-of-mouth-modernization" => {
      title: "Legacy Platform Modernization",
      description: "How we modernized a legacy marketplace without downtime: Strangler Fig cutovers from PHP/jQuery to a headless React and Node stack.",
      keywords: "platform modernization, legacy software modernization, marketplace transformation, zero downtime migration, case study",
      quote_name: nil
    },
    "restaurant-resource-rescue" => {
      title: "Marketplace Search & Stability Rescue",
      description: "How we rescued a restaurant supply marketplace's search and stability: Meilisearch rebuild, Sidekiq hardening, and real-time inventory feeds.",
      keywords: "marketplace search rescue, Meilisearch, SaaS stability, inventory search, case study",
      quote_name: "Brianne Harvey"
    },
    "construction-management-platform" => {
      title: "Construction Platform With QuickBooks Sync",
      description: "How we built one platform for a contractor running three companies: AI estimating, subcontracts, invoicing, and QuickBooks Online sync.",
      keywords: "construction software, construction management platform, QuickBooks integration, subcontract automation, case study",
      quote_name: nil
    }
  }.freeze

  # Quotes keyed by the reviewer's name as stored on /reviews.
  QUOTES = {
    "Nathan" => {
      name: "Nathan",
      role: "Founder, Vestra Software",
      text: "Working with Ahmad has been an incredible experience. They have demonstrated deep technical expertise, clear communication, and a commitment to delivering a high-quality product to our team."
    },
    "Zach Marion" => {
      name: "Zach Marion",
      role: "Founder, Shoreline Waste Solutions",
      text: "A'sTechware have been outstanding partners. They are responsive, detail-oriented, and focused on delivering quality results. I highly recommend them for any project. Looking forward to working with them again in the future."
    },
    "Brianne Harvey" => {
      name: "Brianne Harvey",
      role: "Founder, Restaurant Resource",
      text: "Ahmad has been an exceptional contractor, and we feel incredibly fortunate to have found him. He brings deep technical knowledge to the table, offers thoughtful feedback, and consistently recommends smarter, more efficient solutions."
    },
    "Dale Merritt" => {
      name: "Dale Merritt",
      role: "CEO, Golfpay",
      text: "Been working with Ahmad for almost two years, and he's been great to work with. One of the most reliable developers I've had the pleasure to work with. He's always getting better too."
    },
    "Joseph Chiavatti" => {
      name: "Joseph Chiavatti",
      role: "Technology Founder & REALTOR®",
      text: "Ahmad have helped us with several projects in our company. They are fantastic communicators and do great work. They care about making sure the project is completed the correct way and are quick to communicate on the channels we use."
    }
  }.freeze

  def self.all
    CATALOG
  end

  def self.slugs
    CATALOG.keys
  end

  def self.find(slug)
    CATALOG[slug.to_s]
  end

  def self.quote_for(slug)
    entry = find(slug)
    return nil if entry.blank? || entry[:quote_name].blank?

    QUOTES[entry[:quote_name]]
  end
end
