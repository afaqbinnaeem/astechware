# frozen_string_literal: true

# SEO integration landing pages: slugs, copy, and links to case studies / industries.
class IntegrationCatalog
  INTEGRATIONS = {
    "quickbooks-online" => {
      name: "QuickBooks Online",
      title: "QuickBooks Online Integration",
      meta_description: "QuickBooks Online integration for construction platforms: per-company jobs, cost codes, invoices, and payments synced two-way without duplicate numbering.",
      intro: [
        "We build QuickBooks Online sync layers where the accounting ledger stays authoritative and your operational system stops minting duplicate job, invoice, and cost code records.",
        "On a Las Vegas general contractor platform we shipped, three legally separate companies share one login with per-company QuickBooks accounts, atomic numbering, and Change Data Capture on the Item list.",
        "The integration matches by QuickBooks internal ID, flags unmatched items for human mapping, and never auto-creates near-duplicate cost codes."
      ],
      use_cases: [
        "Multi-company construction platforms that need independent QuickBooks ledgers behind one application login",
        "Job costing when cost codes must be picked from a shared master list mirrored from QuickBooks Online",
        "Pushing estimates, subcontracts, vendor invoices, and subcontractor payments without duplicate numbering in QuickBooks",
        "Starting sequences from existing QuickBooks numbering so cutover does not collide with live books",
        "Contractor platforms replacing PDF templates and manual re-entry between the field and accounting"
      ],
      what_we_build: [
        "OAuth-connected QuickBooks Online adapters with per-company credential isolation",
        "Two-way sync for jobs, items/cost codes, invoices, and payments with ID-level matching",
        "Change Data Capture mirroring of QuickBooks Item lists with human mapping for exceptions",
        "Per-company atomic NumberSequence tables aligned with QuickBooks-bound external IDs",
        "Decimal-safe money fields end to end so synced totals match QuickBooks rounding rules",
        "Monitoring, retry queues, and operator dashboards when sync rows need manual resolution"
      ],
      case_study_slugs: %w[construction-management-platform],
      industry_path: :industry_construction_path,
      industry_label: "Construction software",
      faqs: [
        {
          q: "Can one platform sync multiple QuickBooks Online companies?",
          a: "Yes. On the construction platform we shipped, three companies toggle in the application header, each with its own QuickBooks connection, numbering sequences, and ledger isolation."
        },
        {
          q: "How do you prevent duplicate invoice or job numbers in QuickBooks?",
          a: "We assign numbers inside database transactions with per-company counters, store QuickBooks internal IDs on every pushed record, and bind platform IDs so sync cannot create duplicates."
        },
        {
          q: "Which side owns the cost code list?",
          a: "QuickBooks Online is authoritative. The platform mirrors QuickBooks Items via CDC, enforces pick-only inputs in the UI, and flags unmatched rows for mapping instead of silently creating duplicates."
        },
        {
          q: "Do you support QuickBooks Desktop?",
          a: "We have shipped QuickBooks Online and QuickBooks Desktop. Desktop uses a different connector and conflict model than Online—we scope which edition you need in discovery."
        },
        {
          q: "How long does a QuickBooks integration take?",
          a: "A focused QuickBooks slice on an existing platform often fits a 4–6 week milestone with discovery, entity mapping, error handling, and reconciliation tooling. Multi-company cutovers add mapping time up front."
        }
      ]
    },
    "stripe" => {
      name: "Stripe & Stripe Connect",
      title: "Stripe & Stripe Connect Integration",
      meta_description: "Stripe and Stripe Connect engineering for marketplaces and booking platforms: split payouts, Stripe Terminal, idempotent webhooks, and ledger-first reconciliation.",
      intro: [
        "We integrate Stripe and Stripe Connect where money movement has to stay correct under retries, out-of-order webhooks, and partial outages—not where a button charges a card once.",
        "We have shipped Stripe Connect split payouts for a PropTech marketplace (owner, reserve, and platform fee splits at the point of transaction) and card-present Stripe Terminal flows on a multi-tenant golf booking platform.",
        "Both builds treat payments as ledger events: idempotency keys, webhook verification, and reconciliation queries instead of month-end spreadsheet fixes."
      ],
      use_cases: [
        "Marketplace rent or service payments that split across owners, reserves, and platform fees at charge time",
        "Stripe Connect Custom or Express onboarding with KYC/KYB signals from Plaid or similar providers",
        "Card-present Stripe Terminal on booking or field-service flows alongside online charges",
        "Webhook-driven payout state machines with dead-letter handling when providers retry events",
        "Booking or logistics platforms that need Stripe alongside operational triggers (confirmations, invoices)"
      ],
      what_we_build: [
        "Double-entry ledger modules that record charges before bank movements",
        "Split rule engines versioned per transaction type with audit-friendly logs",
        "Stripe Connect account onboarding, capability checks, and payout scheduling",
        "Stripe Terminal and PaymentIntent flows with idempotent capture paths",
        "Webhook ingestion with signature verification, replay protection, and idempotency stores",
        "Operator tooling for stuck payouts, dispute trails, and safe test environments"
      ],
      case_study_slugs: %w[vestra-payments golfpay360-saas shoreline-waste-logistics],
      industry_path: :industry_financial_path,
      industry_label: "Fintech & payments",
      faqs: [
        {
          q: "Do you implement Stripe Connect Standard, Express, or Custom?",
          a: "We have shipped Stripe Connect Custom/Express patterns on marketplace platforms. The right account type depends on who owns onboarding UX and liability— we map that in discovery."
        },
        {
          q: "How do you prevent duplicate charges or split errors?",
          a: "Every charge, split, and payout carries an idempotency key. Webhooks update state machines; exhausted retries land in queues your team can replay safely."
        },
        {
          q: "Have you integrated Stripe Terminal?",
          a: "Yes on GolfPay360: card-present Stripe Terminal alongside Clover and Square POS SDKs on a high-concurrency booking platform."
        },
        {
          q: "Can Stripe trigger downstream ops workflows?",
          a: "On Shoreline Waste we connected completion and billing flows so operational events and Stripe charges stay aligned. Patterns are similar for confirmations or invoices on other platforms."
        },
        {
          q: "Are you a PCI-certified processor?",
          a: "We design flows to support PCI DSS expectations and tokenize card data through Stripe. We do not claim PCI certification on your behalf."
        }
      ]
    },
    "payment-gateway-migration" => {
      name: "Payment Processor Migration",
      title: "Payment Processor Migration",
      meta_description: "Payment processor migration for booking and SaaS platforms: cut over online and card-present rails with reconciliation, webhooks, and idempotent charges.",
      intro: [
        "Processor migrations fail when teams treat them as a config swap instead of a money-state problem: open authorizations, saved payment methods, historical reconciliation, and in-flight subscriptions all have to land cleanly.",
        "Our shipped payment work on GolfPay360—Stripe Terminal plus Clover and Square POS SDKs on a serverless booking stack—shows how we design rails, locks, and reconciliation so peak traffic does not double-charge.",
        "We have built multi-processor payment rails (including processor migrations and greenfield Stripe/Clover/Square integrations) with parallel-run cutover plans when you need them."
      ],
      use_cases: [
        "Booking or SaaS platforms adding Stripe Terminal or a new processor alongside legacy POS SDKs",
        "Cutting card-present and online flows over without double bookings or double charges during peak events",
        "Replaying webhook history to rebuild ledger balances before decommissioning an old processor",
        "Mapping saved customer payment methods and merchant accounts per tenant on multi-tenant products",
        "Fintech or marketplace products that must keep split-payout rules stable while changing processors"
      ],
      what_we_build: [
        "Migration runbooks with parallel-run or phased cutover options and rollback gates",
        "Ledger backfills that reconcile legacy processor exports against in-app balances",
        "Idempotent charge and refund adapters shared across old and new rails during transition",
        "Webhook consolidation layers that normalize events into one internal money model",
        "POS and Terminal integration testing under concurrency and offline retries",
        "Monitoring and alerting for divergence between processor dashboards and your database ledger"
      ],
      case_study_slugs: %w[golfpay360-saas],
      industry_path: :industry_financial_path,
      industry_label: "Fintech & payments",
      faqs: [
        {
          q: "Have you migrated production traffic between payment processors?",
          a: "Yes. We have shipped Stripe Terminal, Clover, and Square on GolfPay360 and run processor migrations with parallel-run plans when cutting over production traffic."
        },
        {
          q: "How do you avoid double charges during cutover?",
          a: "Distributed locks, idempotent PaymentIntent or charge IDs, and feature flags that route new checkouts to one processor at a time while in-flight authorizations expire cleanly."
        },
        {
          q: "Can you migrate card-present and online together?",
          a: "Yes when the architecture shares one ledger. We sequence Terminal/POS cutovers separately from e-commerce if hardware certification timelines differ."
        },
        {
          q: "What data do you need from the old processor?",
          a: "Settlement files, charge IDs, refund history, and customer token maps. We inventory gaps in discovery before promising a timeline."
        }
      ]
    },
    "twilio" => {
      name: "Twilio",
      title: "Twilio SMS, Voice & AI Phone Agents",
      meta_description: "Twilio SMS, voice, and AI phone agent integration for clinics and home services: programmable voice, MMS ingestion, and telephony wired to your workflows.",
      intro: [
        "We integrate Twilio where messaging or voice is part of a regulated or revenue-critical workflow—not as a one-off SMS alert bolted on at the end.",
        "We have shipped Twilio programmable voice for HIPAA-ready clinic booking, MMS ingestion for HVAC technicians texting job photos, and Twilio SMS alerts on a real estate showing platform.",
        "Patterns include BAA-covered telephony paths, approval gates before public posts, and de-identified LLM layers when voice agents reason over clinical intent."
      ],
      use_cases: [
        "After-hours and overflow voice booking for clinics with transcripts routed to staff queues",
        "MMS-to-workflow ingestion so field staff text photos without installing another app",
        "SMS confirmations and alerts tied to showing requests, dispatch events, or booking commits",
        "AI phone agents with latency-optimized paths and human escalation when confidence drops",
        "Two-way SMS threads logged against job, listing, or patient records for auditability"
      ],
      what_we_build: [
        "Twilio Voice call flows with recording policies aligned to your compliance posture",
        "Programmable Messaging webhooks with signature validation and idempotent handlers",
        "MMS media download pipelines with metadata stripping and secure storage",
        "Bridging telephony events to booking, dispatch, or marketing approval dashboards",
        "Queue and staff notification wiring when calls arrive outside business hours",
        "Observability on delivery failures, latency, and carrier error codes"
      ],
      case_study_slugs: %w[medical-voice-ai red-dragon-hvac instashowing-real-estate],
      industry_path: :industry_private_clinics_path,
      industry_label: "Private clinics",
      faqs: [
        {
          q: "Have you built HIPAA-ready Twilio voice flows?",
          a: "Yes. On our private clinic project we use Twilio telephony on BAA-covered infrastructure with PHI de-identification before LLM calls and no long-term audio retention on the scribe path."
        },
        {
          q: "Can technicians use SMS only?",
          a: "On Red Dragon HVAC, technicians text MMS photos; Twilio ingests media, strips metadata, and routes captions through an approval dashboard before Google or Meta publishing."
        },
        {
          q: "Do you build conversational IVR or AI agents on Twilio?",
          a: "We ship natural-language voice agents when latency and compliance constraints are designed first—deterministic fallbacks when models or carriers fail."
        },
        {
          q: "Which regions do you support?",
          a: "We deploy for teams in the United States, United Kingdom, Canada, and Australia, selecting Twilio numbers and routing based on your compliance and data residency needs."
        },
        {
          q: "Can Twilio trigger billing or ops events?",
          a: "On InstaShowing, Twilio SMS alerts participate in the showing workflow. Similar patterns apply when SMS must confirm appointments or dispatch updates."
        }
      ]
    },
    "microsoft-365-outlook" => {
      name: "Microsoft 365 & Outlook",
      title: "Microsoft 365 & Outlook Email Automation",
      meta_description: "Microsoft 365 and Outlook automation for construction teams: vendor bills from shared mailboxes matched to subcontracts and jobs without retyping.",
      intro: [
        "Construction and ops teams drown in subcontract PDFs, insurance certificates, and vendor bills that arrive in Outlook long before they belong in a job ledger.",
        "On the construction management platform we shipped, Microsoft 365 shared mailboxes feed vendor invoice ingestion matched to subcontracts, alongside QuickBooks Online sync per company.",
        "The goal is email as an input channel with the same auditability as in-app records— not another inbox your PMs must search manually."
      ],
      use_cases: [
        "Shared mailbox ingestion that attaches vendor bills to the correct job and subcontract",
        "Parsing subcontractor replies and insurance certificates into structured job records",
        "Routing estimate and contract PDFs generated in-app back through Outlook threads stakeholders already watch",
        "Multi-company construction groups where each entity has different branding but shared estimating staff",
        "Reducing retyping between Outlook, estimating tools, and accounting systems"
      ],
      what_we_build: [
        "Microsoft Graph / Outlook integrations with least-privilege OAuth scopes",
        "Mailbox listeners that classify attachments and match them to open subcontracts",
        "Human review queues when parser confidence is low or multiple jobs match",
        "Ties between email-derived bills and payment guards (signed contract, current insurance)",
        "Audit logs on every automated mailbox action and manual override",
        "Retry and dead-letter handling when Graph throttles or messages arrive out of order"
      ],
      case_study_slugs: %w[construction-management-platform],
      industry_path: :industry_construction_path,
      industry_label: "Construction software",
      faqs: [
        {
          q: "Do you read shared mailboxes or individual inboxes?",
          a: "On the construction platform, vendor billing centers on shared mailboxes tied to job records. We scope mailbox types and consent models in discovery."
        },
        {
          q: "How do you match an email to the right subcontract?",
          a: "We combine vendor identifiers, job numbers, and attachment fingerprints. Ambiguous matches surface in a review UI instead of posting silently to the wrong job."
        },
        {
          q: "Does this replace QuickBooks?",
          a: "No. Outlook automation feeds operational records; QuickBooks Online remains the accounting system of record with synced invoices and payments."
        },
        {
          q: "What about Microsoft 365 security requirements?",
          a: "We use tenant-scoped OAuth, store refresh tokens securely, and document scopes for your IT review. Typical Microsoft 365 setups use an admin consent flow so your tenant admin approves the app once."
        }
      ]
    },
    "google-business-profile" => {
      name: "Google Business Profile",
      title: "Google Business Profile Automation",
      meta_description: "Google Business Profile API integration for home services: MMS job photos turned into approval-gated local posts with Vision AI captions and manager review.",
      intro: [
        "Home services companies lose map-pack visibility when technicians complete great work but nobody publishes fresh, location-relevant proof.",
        "For Red Dragon HVAC we built a headless pipeline: Twilio MMS ingestion, metadata stripping, Vision AI captions, and management approval before posts hit Google Business Profile (and Meta when enabled).",
        "Technicians only send a text; marketers approve; local SEO content stays accurate without spammy keyword stuffing."
      ],
      use_cases: [
        "Daily photo-verified Google posts from field crews without asking them to write copy",
        "Approval dashboards that block publishing until managers review Vision-generated captions",
        "Stripping sensitive EXIF metadata while keeping city or neighborhood context for local SEO",
        "Publishing the same approved asset to Google Business Profile and Meta with one workflow",
        "Equipment-aware captions (for example furnace or AC model names) that stay technically credible"
      ],
      what_we_build: [
        "Google Business Profile API publishing with OAuth and location scoping",
        "Event-driven MMS ingestion via Twilio with secure media fetch and storage",
        "Vision AI captioning with guardrails and human kill-switches",
        "GPS or job-context enrichment for localized keywords without fabricating addresses",
        "Dashboards showing draft, approved, and live post states per technician",
        "Failure alerts when Google or Meta APIs reject media or rate-limit publishing"
      ],
      case_study_slugs: %w[red-dragon-hvac],
      industry_path: :industry_home_services_path,
      industry_label: "HVAC & home services",
      faqs: [
        {
          q: "Do technicians need a mobile app?",
          a: "No on Red Dragon HVAC—they text MMS photos. The pipeline handles ingestion, enrichment, and publishing after manager approval."
        },
        {
          q: "Can you publish to Facebook or Instagram too?",
          a: "Yes. The same case study integrates Meta Graph API with the same approval gate before anything goes live."
        },
        {
          q: "How do you keep captions from sounding like spam?",
          a: "Vision AI drafts natural language; managers edit or reject. Equipment labels come from recognized objects, not generic SEO templates."
        },
        {
          q: "What access do you need to Google Business Profile?",
          a: "OAuth to the locations you authorize. We document required roles for your marketing lead and IT admin during setup."
        }
      ]
    },
    "docusign" => {
      name: "DocuSign",
      title: "DocuSign Integration",
      meta_description: "DocuSign integration for legal and real estate workflows: signing order enforcement, offer packages, and audit trails on every document view.",
      intro: [
        "DocuSign integrations fail when envelopes are treated as attachments instead of state machines tied to your database.",
        "We have shipped enforced signing order for court-grade affidavits on a Canadian process serving platform (server first, then commissioner) and DocuSign on offer workflows for InstaShowing.",
        "Both tie webhook status back to operational records so staff cannot advance invoices, payments, or listing stages until signatures match business rules."
      ],
      use_cases: [
        "Process serving affidavits with ordered signers and immutable audit logs",
        "Real estate offer packages with encrypted attachments and view tracking",
        "Subcontract execution gates that block payments until DocuSign shows EXECUTED status",
        "Multi-tenant SaaS where each customer brings their own DocuSign account or shares a platform envelope",
        "Webhook-driven status updates that reconcile partial signings and voided envelopes"
      ],
      what_we_build: [
        "DocuSign envelope builders populated from your case, listing, or job records",
        "Signing order enforcement and recipient role mapping",
        "Webhook handlers that update internal state machines idempotently",
        "Storage of completed PDFs with tamper-evident hashes linked to source records",
        "Staff UI for resend, void, and correct recipient mistakes without breaking audit trails",
        "Sandbox-to-production promotion checklists and embedded signing where appropriate"
      ],
      case_study_slugs: %w[flss-legal-process-serving instashowing-real-estate],
      industry_path: :industry_legal_path,
      industry_label: "Legal operations",
      faqs: [
        {
          q: "Have you wired DocuSign into court or compliance workflows?",
          a: "Yes, for a Canadian process serving company: affidavits move through DocuSign with server-then-commissioner order; signed PDFs return to law firms with evidence tied to attempt logs."
        },
        {
          q: "Can DocuSign gate payments or job status?",
          a: "On the construction platform, payments require EXECUTED subcontract status. DocuSign patterns are similar wherever signature state must block money movement."
        },
        {
          q: "Do you support embedded signing?",
          a: "Yes. We choose embedded vs email invite per UX and compliance needs, and have shipped both patterns."
        },
        {
          q: "How do you handle webhook retries?",
          a: "Signature verification, idempotent status transitions, and logs so duplicate Completed events cannot double-advance a record."
        }
      ]
    },
    "fhir-ehr" => {
      name: "FHIR & EHR",
      title: "FHIR & EHR Integration",
      meta_description: "FHIR and EHR integration for healthcare platforms: bi-directional FHIR R4 sync, SMART on FHIR authorization, and adapters proven with athenahealth.",
      intro: [
        "Healthcare integrations fail when teams treat FHIR like a REST CRUD exercise instead of a conflict, consent, and audit problem.",
        "We shipped bi-directional FHIR R4 sync with athenahealth on a HIPAA-ready voice booking and AI scribe platform: SMART on FHIR authorization, adapter patterns for other FHIR-capable EHRs, and clinical notes that require provider approval before they touch the chart.",
        "We describe the platform as HIPAA-ready, not HIPAA compliant—your operational controls and BAAs still define compliance."
      ],
      use_cases: [
        "Bi-directional appointment and availability sync between a patient-facing app and athenahealth",
        "Pushing provider-approved SOAP notes to the EHR after AI-assisted drafting",
        "Adapter layers that add Epic, Cerner, or eClinicalWorks without rewriting the patient app",
        "Conflict detection when the EHR and your platform both edit the same slot or document",
        "Audit trails on every FHIR read and write for compliance reviews"
      ],
      what_we_build: [
        "SMART on FHIR OAuth flows with token refresh and scoped least privilege",
        "FHIR R4 resource mappers for appointments, patients, practitioners, and clinical notes",
        "Reconciliation jobs that detect drift between your cache and the EHR",
        "Provider approval queues before outbound clinical documents post",
        "PHI boundaries so de-identified AI layers never receive raw identifiers",
        "Monitoring on throttling, partial batches, and failed writes with replay tooling"
      ],
      case_study_slugs: %w[medical-voice-ai],
      industry_path: :industry_healthcare_path,
      industry_label: "Healthcare AI",
      faqs: [
        {
          q: "Which EHR have you integrated in production?",
          a: "athenahealth FHIR R4 bi-directionally on our private clinic project. Additional FHIR-capable EHRs are adapter implementations on the same integration layer—not greenfield rebuilds."
        },
        {
          q: "Is the integration HIPAA compliant?",
          a: "We build HIPAA-ready systems with BAAs, access controls, and audit logging appropriate to your role. We do not claim HIPAA compliance on your behalf without your policies and vendor chain in place."
        },
        {
          q: "Can AI write directly into the chart?",
          a: "No on the shipped platform. Providers approve SOAP notes before FHIR writes. The LLM never sees patient identifiers in prompts."
        },
        {
          q: "Do you support HL7 v2 as well as FHIR?",
          a: "Yes. Our primary documented production path is FHIR R4 with athenahealth; we have also shipped HL7 v2 interfaces when hospitals require them."
        },
        {
          q: "How do you handle EHR downtime?",
          a: "Queues, cached reads where safe, and explicit failure surfaces so front desk staff know when booking must fall back to manual EHR entry."
        }
      ]
    },
    "reso-mls" => {
      name: "MLS & RESO",
      title: "MLS & RESO Web API Integration",
      meta_description: "MLS and RESO Web API integration for real estate platforms: listing data in showing and offer workflows without retyping fields from the MLS.",
      intro: [
        "Showing and offer tools break when listing data is copied from MLS exports that are already stale.",
        "On InstaShowing we integrated RESO Web API for MLS listing data alongside DocuSign offer flows and Twilio SMS alerts—one ledger for showings, feedback, and offers.",
        "We use adapter patterns so different boards or RESO variants map into one internal listing model your scheduling UI can trust."
      ],
      use_cases: [
        "Pulling live listing fields into showing request and approval workflows",
        "Keeping agent-facing availability in sync with MLS status changes",
        "Feeding offer documents with listing identifiers and parties without manual re-entry",
        "Board-specific RESO quirks isolated in adapters so the app layer stays stable",
        "Combining MLS data with calendar sync across Google, Outlook, and iCloud"
      ],
      what_we_build: [
        "RESO Web API clients with OAuth and board-specific field mapping",
        "Normalized listing caches with TTL and change detection",
        "Hooks from listing updates into showing rules and marketing assets",
        "Audit logs when agents view or export offer attachments",
        "Fallback handling when boards throttle or partial feeds fail overnight",
        "Test fixtures from sandbox MLS datasets before production keys"
      ],
      case_study_slugs: %w[instashowing-real-estate],
      industry_path: :industry_real_estate_path,
      industry_label: "Real estate software",
      faqs: [
        {
          q: "Have you integrated RESO Web API in production?",
          a: "Yes on InstaShowing for MLS listing data alongside showing scheduling and offer management."
        },
        {
          q: "Can you support non-RESO MLS feeds?",
          a: "When a board exposes a documented API or RETS/RESO variant, we implement an adapter. Feasibility depends on the board's contractual and technical access—confirmed in discovery."
        },
        {
          q: "How do you keep MLS data fresh?",
          a: "Scheduled sync plus change hooks where the board supports them, with visible timestamps so agents know when a listing last updated."
        },
        {
          q: "Does MLS integration include CRM features?",
          a: "Our shipped MLS-backed scope is operational: showings, feedback, and offers. CRM-style nurture flows are a separate scope when you need them."
        }
      ]
    }
  }.freeze

  INDEX_META_DESCRIPTION = "Integrations we ship in production: QuickBooks, Stripe, Twilio, Outlook, DocuSign, FHIR and MLS for teams in the US, UK, Canada and Australia.".freeze

  def self.all
    INTEGRATIONS
  end

  def self.slugs
    INTEGRATIONS.keys
  end

  def self.find(slug)
    INTEGRATIONS[slug.to_s]
  end

  def self.ordered
    INTEGRATIONS.sort_by { |_slug, entry| entry[:name].to_s.downcase }
  end
end