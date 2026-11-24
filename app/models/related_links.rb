# frozen_string_literal: true

# Path-keyed related internal links for SEO Part 10 (services, industries, case studies, hire, integrations).
# Each entry: { label:, path: } where path is a route helper Symbol or a site path String.
class RelatedLinks
  MAPPING = {
  # —— Services ——
    "services/ai-agent-development" => [
      { label: "Healthcare AI solutions", path: :industry_healthcare_path },
      { label: "Legal tech engineering", path: :industry_legal_path },
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" },
      { label: "Hire AI engineers", path: :hire_ai_engineers_path }
    ],
    "services/machine-learning" => [
      { label: "AI agent development", path: :ai_agent_development_path },
      { label: "Real estate deal analyzer", path: -> { case_study_path("ai-deal-analyzer") } },
      { label: "Financial / fintech solutions", path: :industry_financial_path },
      { label: "API & system integrations", path: :api_integrations_path },
      { label: "All case studies", path: :case_studies_path }
    ],
    "services/platform-modernization" => [
      { label: "Word-of-mouth modernization", path: -> { case_study_path("word-of-mouth-modernization") } },
      { label: "Restaurant marketplace rescue", path: -> { case_study_path("restaurant-resource-rescue") } },
      { label: "DevOps & cloud engineering", path: :devops_engineering_path },
      { label: "Custom software", path: :custom_software_path },
      { label: "How we de-risk projects", path: :derisk_projects_path }
    ],
    "services/custom-software" => [
      { label: "FLSS legal platform case study", path: -> { case_study_path("flss-legal-process-serving") } },
      { label: "Construction management platform", path: -> { case_study_path("construction-management-platform") } },
      { label: "Construction industry solutions", path: :industry_construction_path },
      { label: "Hire dedicated developers", path: :hire_dedicated_developers_path },
      { label: "GCC delivery model", path: :gcc_path }
    ],
    "services/api-integrations" => [
      { label: "Integrations hub", path: :integrations_path },
      { label: "QuickBooks Online", path: "/integrations/quickbooks-online" },
      { label: "Stripe & Stripe Connect", path: "/integrations/stripe" },
      { label: "FHIR / EHR", path: "/integrations/fhir-ehr" },
      { label: "DevOps engineering", path: :devops_engineering_path }
    ],
    "services/devops-engineering" => [
      { label: "Platform modernization", path: :platform_modernization_path },
      { label: "Word-of-mouth modernization", path: -> { case_study_path("word-of-mouth-modernization") } },
      { label: "GolfPay360 SaaS case study", path: -> { case_study_path("golfpay360-saas") } },
      { label: "Methodology", path: :methodology_path },
      { label: "Hire dedicated developers", path: :hire_dedicated_developers_path }
    ],
    "services" => [
      { label: "AI agent development", path: :ai_agent_development_path },
      { label: "Machine learning engineering", path: :machine_learning_path },
      { label: "DevOps & cloud engineering", path: :devops_engineering_path },
      { label: "Integrations hub", path: :integrations_path },
      { label: "Case studies", path: :case_studies_path }
    ],

  # —— Industries / solutions ——
    "solutions/healthcare" => [
      { label: "Private clinics", path: :industry_private_clinics_path },
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } },
      { label: "FHIR / EHR integration", path: "/integrations/fhir-ehr" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "solutions/private-clinics" => [
      { label: "Healthcare AI engineering", path: :industry_healthcare_path },
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } },
      { label: "FHIR / EHR integration", path: "/integrations/fhir-ehr" },
      { label: "Hire AI engineers", path: :hire_ai_engineers_path }
    ],
    "solutions/legal" => [
      { label: "FLSS process serving case study", path: -> { case_study_path("flss-legal-process-serving") } },
      { label: "DocuSign integration", path: "/integrations/docusign" },
      { label: "Custom software development", path: :custom_software_path },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "solutions/financial" => [
      { label: "Stripe & Stripe Connect", path: "/integrations/stripe" },
      { label: "Vestra payments case study", path: -> { case_study_path("vestra-payments") } },
      { label: "Zofi earned wage access", path: -> { case_study_path("zofi-cash-fintech") } },
      { label: "Machine learning engineering", path: :machine_learning_path }
    ],
    "solutions/construction" => [
      { label: "Construction platform case study", path: -> { case_study_path("construction-management-platform") } },
      { label: "QuickBooks Online integration", path: "/integrations/quickbooks-online" },
      { label: "Microsoft 365 / Outlook", path: "/integrations/microsoft-365-outlook" },
      { label: "Custom software", path: :custom_software_path }
    ],
    "solutions/logistics" => [
      { label: "Shoreline waste logistics case study", path: -> { case_study_path("shoreline-waste-logistics") } },
      { label: "Stripe integration", path: "/integrations/stripe" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" },
      { label: "API integrations services", path: :api_integrations_path }
    ],
    "solutions/home-services" => [
      { label: "Red Dragon HVAC case study", path: -> { case_study_path("red-dragon-hvac") } },
      { label: "Google Business Profile", path: "/integrations/google-business-profile" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "solutions/real-estate" => [
      { label: "InstaShowing case study", path: -> { case_study_path("instashowing-real-estate") } },
      { label: "AI deal analyzer", path: -> { case_study_path("ai-deal-analyzer") } },
      { label: "RESO / MLS integration", path: "/integrations/reso-mls" },
      { label: "Custom software", path: :custom_software_path }
    ],
    "solutions/b2b-saas" => [
      { label: "GolfPay360 case study", path: -> { case_study_path("golfpay360-saas") } },
      { label: "Restaurant marketplace rescue", path: -> { case_study_path("restaurant-resource-rescue") } },
      { label: "EventVesta marketing automation", path: -> { case_study_path("eventvesta-ai-marketing") } },
      { label: "Platform modernization", path: :platform_modernization_path }
    ],
    "solutions/professional-services" => [
      { label: "Construction software", path: :industry_construction_path },
      { label: "Logistics automation", path: :industry_logistics_path },
      { label: "Shoreline logistics case study", path: -> { case_study_path("shoreline-waste-logistics") } },
      { label: "Real estate solutions", path: :industry_real_estate_path }
    ],
    "solutions/education-technology" => [
      { label: "Custom software development", path: :custom_software_path },
      { label: "B2B SaaS engineering", path: :industry_b2b_saas_path },
      { label: "FLSS multi-tenant SaaS case study", path: -> { case_study_path("flss-legal-process-serving") } },
      { label: "Machine learning engineering", path: :machine_learning_path }
    ],

  # —— Case studies ——
    "case-studies/medical-voice-ai" => [
      { label: "Healthcare AI engineering", path: :industry_healthcare_path },
      { label: "Private clinics", path: :industry_private_clinics_path },
      { label: "FHIR / EHR integration", path: "/integrations/fhir-ehr" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" }
    ],
    "case-studies/flss-legal-process-serving" => [
      { label: "Legal tech engineering", path: :industry_legal_path },
      { label: "DocuSign integration", path: "/integrations/docusign" },
      { label: "Custom software development", path: :custom_software_path }
    ],
    "case-studies/construction-management-platform" => [
      { label: "Construction industry solutions", path: :industry_construction_path },
      { label: "QuickBooks Online integration", path: "/integrations/quickbooks-online" },
      { label: "Microsoft 365 / Outlook", path: "/integrations/microsoft-365-outlook" }
    ],
    "case-studies/shoreline-waste-logistics" => [
      { label: "Logistics automation", path: :industry_logistics_path },
      { label: "Stripe integration", path: "/integrations/stripe" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" }
    ],
    "case-studies/red-dragon-hvac" => [
      { label: "Home services solutions", path: :industry_home_services_path },
      { label: "Google Business Profile", path: "/integrations/google-business-profile" },
      { label: "Twilio voice & SMS", path: "/integrations/twilio" }
    ],
    "case-studies/vestra-payments" => [
      { label: "Financial / fintech", path: :industry_financial_path },
      { label: "Real estate solutions", path: :industry_real_estate_path },
      { label: "Stripe & Stripe Connect", path: "/integrations/stripe" }
    ],
    "case-studies/zofi-cash-fintech" => [
      { label: "Financial / fintech", path: :industry_financial_path },
      { label: "Stripe integration", path: "/integrations/stripe" },
      { label: "Custom software", path: :custom_software_path }
    ],
    "case-studies/golfpay360-saas" => [
      { label: "B2B SaaS engineering", path: :industry_b2b_saas_path },
      { label: "Stripe integration", path: "/integrations/stripe" },
      { label: "DevOps & cloud", path: :devops_engineering_path }
    ],
    "case-studies/instashowing-real-estate" => [
      { label: "Real estate solutions", path: :industry_real_estate_path },
      { label: "RESO / MLS integration", path: "/integrations/reso-mls" },
      { label: "AI deal analyzer case study", path: -> { case_study_path("ai-deal-analyzer") } }
    ],
    "case-studies/ai-deal-analyzer" => [
      { label: "Real estate solutions", path: :industry_real_estate_path },
      { label: "Machine learning engineering", path: :machine_learning_path },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "case-studies/word-of-mouth-modernization" => [
      { label: "Platform modernization", path: :platform_modernization_path },
      { label: "DevOps engineering", path: :devops_engineering_path },
      { label: "Custom software", path: :custom_software_path }
    ],
    "case-studies/restaurant-resource-rescue" => [
      { label: "B2B SaaS engineering", path: :industry_b2b_saas_path },
      { label: "Platform modernization", path: :platform_modernization_path },
      { label: "Custom software", path: :custom_software_path }
    ],
    "case-studies/eventvesta-ai-marketing" => [
      { label: "B2B SaaS engineering", path: :industry_b2b_saas_path },
      { label: "AI agent development", path: :ai_agent_development_path },
      { label: "How we de-risk projects", path: :derisk_projects_path }
    ],

  # —— Hire ——
    "hire-ai-engineers" => [
      { label: "AI agent development", path: :ai_agent_development_path },
      { label: "Machine learning engineering", path: :machine_learning_path },
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } },
      { label: "Healthcare solutions", path: :industry_healthcare_path },
      { label: "Methodology", path: :methodology_path }
    ],
    "hire-dedicated-developers" => [
      { label: "Custom software development", path: :custom_software_path },
      { label: "Platform modernization", path: :platform_modernization_path },
      { label: "GCC delivery model", path: :gcc_path },
      { label: "Case studies", path: :case_studies_path },
      { label: "Services overview", path: :services_path }
    ],

  # —— Integrations hub ——
    "integrations" => [
      { label: "API integration services", path: :api_integrations_path },
      { label: "QuickBooks Online", path: "/integrations/quickbooks-online" },
      { label: "Stripe", path: "/integrations/stripe" },
      { label: "Construction case study", path: -> { case_study_path("construction-management-platform") } }
    ],

  # —— Integration detail pages ——
    "integrations/quickbooks-online" => [
      { label: "Construction industry", path: :industry_construction_path },
      { label: "Construction platform case study", path: -> { case_study_path("construction-management-platform") } },
      { label: "API integration services", path: :api_integrations_path },
      { label: "Microsoft 365 / Outlook", path: "/integrations/microsoft-365-outlook" }
    ],
    "integrations/stripe" => [
      { label: "Financial / fintech", path: :industry_financial_path },
      { label: "Vestra payments case study", path: -> { case_study_path("vestra-payments") } },
      { label: "GolfPay360 case study", path: -> { case_study_path("golfpay360-saas") } },
      { label: "Payment gateway migration", path: "/integrations/payment-gateway-migration" }
    ],
    "integrations/twilio" => [
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } },
      { label: "Shoreline logistics case study", path: -> { case_study_path("shoreline-waste-logistics") } },
      { label: "Red Dragon HVAC case study", path: -> { case_study_path("red-dragon-hvac") } },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "integrations/microsoft-365-outlook" => [
      { label: "Construction industry", path: :industry_construction_path },
      { label: "Construction platform case study", path: -> { case_study_path("construction-management-platform") } },
      { label: "QuickBooks Online", path: "/integrations/quickbooks-online" },
      { label: "Custom software", path: :custom_software_path }
    ],
    "integrations/google-business-profile" => [
      { label: "Home services solutions", path: :industry_home_services_path },
      { label: "Red Dragon HVAC case study", path: -> { case_study_path("red-dragon-hvac") } },
      { label: "AI agent development", path: :ai_agent_development_path }
    ],
    "integrations/docusign" => [
      { label: "Legal tech engineering", path: :industry_legal_path },
      { label: "FLSS case study", path: -> { case_study_path("flss-legal-process-serving") } },
      { label: "Real estate solutions", path: :industry_real_estate_path }
    ],
    "integrations/fhir-ehr" => [
      { label: "Healthcare AI engineering", path: :industry_healthcare_path },
      { label: "Private clinics", path: :industry_private_clinics_path },
      { label: "Medical voice AI case study", path: -> { case_study_path("medical-voice-ai") } }
    ],
    "integrations/reso-mls" => [
      { label: "Real estate solutions", path: :industry_real_estate_path },
      { label: "InstaShowing case study", path: -> { case_study_path("instashowing-real-estate") } },
      { label: "Custom software", path: :custom_software_path }
    ],
    "integrations/payment-gateway-migration" => [
      { label: "Stripe integration", path: "/integrations/stripe" },
      { label: "Financial / fintech", path: :industry_financial_path },
      { label: "Vestra payments case study", path: -> { case_study_path("vestra-payments") } }
    ]
  }.freeze

  def self.normalize_key(path)
    path.to_s.sub(%r{\A/}, "").sub(%r{/\z}, "")
  end

  def self.for_path(path)
    key = normalize_key(path)
    MAPPING[key]
  end
end