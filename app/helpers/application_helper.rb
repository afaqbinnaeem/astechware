# frozen_string_literal: true

module ApplicationHelper
  # Safely get image URL for Open Graph meta tags
  # Returns absolute URL or nil if asset doesn't exist (prevents 500 errors)
  def safe_og_image_url(image_name = 'logo-colored.png')
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

  # Full URL for OG image (1200x630). Use public/og-image.png in production.
  def seo_og_image_url
    base = Rails.env.production? ? "https://astechware.com" : "#{request.protocol}#{request.host_with_port}"
    "#{base}/og-image.png"
  end

  # Get reCAPTCHA site key for frontend
  def recaptcha_site_key
    ENV['RECAPTCHA_SITE_KEY'] || Rails.application.credentials.dig(:recaptcha, :site_key)
  end
  # Blog articles for Insights & Resources landing (path, metadata). Replace with DB later.
  def blog_articles_list
    [
      # Expert AI series (production-first, what agencies miss)
      { slug: "ai-chatbot-death-spiral", path: -> { blog_show_path("ai-chatbot-death-spiral") }, title: "The AI Chatbot Death Spiral: Why Demos Work But Production Fails", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Your AI chatbot launched at 95% accuracy. Two months later, customers are complaining. Why chatbots degrade and how to fix it with continuous improvement.", excerpt_long: "Agencies demo with curated data and have no plan for accuracy degradation. In production, user language evolves, edge cases accumulate, and model drift goes unnoticed until customers complain. We break down the chatbot death spiral—Week 1: 95% → Week 8: 60%—and the monitoring, feedback loops, and retraining strategies that actually keep production chatbots reliable.", read_time: "11 min", date: "Feb 2025", image: "ahmad/repi-work.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "ai-cost-explosion", path: -> { blog_show_path("ai-cost-explosion") }, title: "AI Cost Explosion: The Mistakes Burning $50K/Month", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI feature costs $50K/month. It should cost $8K. Smart model routing, caching, and token optimization without sacrificing quality.", excerpt_long: "Using GPT-4 for everything, no caching, and inefficient prompts burn budgets fast. We cover cost attribution, model tiering, semantic caching, prompt compression, and the math that gets legal tech from $40K to $16K—with real strategies you can apply this week.", read_time: "10 min", date: "Feb 2025", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "prompt-injection-security", path: -> { blog_show_path("prompt-injection-security") }, title: "Prompt Injection: How Hackers Hijack Your AI (And How to Stop Them)", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "Your AI agent just emailed your entire customer database to an attacker. What prompt injection is and defense-in-depth that works.", excerpt_long: "Adversarial inputs, no output filtering, and agents with too many permissions create real incidents. We walk through types of prompt injection, input sanitization and output validation that work, privilege separation for agents, and how to red-team your own AI before someone else does.", read_time: "12 min", date: "Feb 2025", image: "ahmad/3agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "rag-implementation-mistakes", path: -> { blog_show_path("rag-implementation-mistakes") }, title: "RAG Implementation Mistakes That Kill Accuracy (And How to Fix Them)", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You gave your AI access to all your docs. It still makes things up. Bad chunking, wrong embeddings, and no re-ranking—and how to fix them.", excerpt_long: "Naive chunking, bad embeddings, and no confidence filtering lead to hallucinations despite 'having the data.' We cover chunking that preserves meaning, hybrid search, re-ranking with cross-encoders, and prompt engineering for RAG—plus when to use fine-tuning instead.", read_time: "11 min", date: "Feb 2025", image: "blogs/turbo_astechware.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "agentic-ai-governance", path: -> { blog_show_path("agentic-ai-governance") }, title: "Agentic AI: Why 'Just Let It Do Things' Is a Recipe for Disaster", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "Your AI agent just deleted 10,000 records because a user said 'clean this up.' Scoped permissions, approval workflows, and audit trails that scale.", excerpt_long: "Agents with too many permissions and no approval workflows cause real damage. We outline the governance framework: scoped permissions, human-in-the-loop for critical actions, dry-run mode, confidence thresholds, rate limiting, audit logging, rollback, and testing for adversarial scenarios—with SOC 2 and HIPAA in mind.", read_time: "12 min", date: "Feb 2025", image: "ahmad/whatsapp-agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "fine-tuning-vs-prompting", path: -> { blog_show_path("fine-tuning-vs-prompting") }, title: "The Fine-Tuning Decision: When Custom Models Beat Prompt Engineering", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your legal AI costs $15K/month in API calls. A $80K fine-tuned model could pay for itself in 6 months. When and how to decide.", excerpt_long: "When prompting is enough versus when fine-tuning wins—domain-specific language, volume, accuracy plateaus, and cost. We include the ROI calculation, data requirements, LoRA vs full fine-tuning, and real examples: customer support, medical coding, and legal contract analysis with 10x cost reduction.", read_time: "10 min", date: "Feb 2025", image: "blogs/astechware_new_web_blog_2.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "context-window-lost-in-middle", path: -> { blog_show_path("context-window-lost-in-middle") }, title: "Lost in the Middle: Why Large Context Windows Don't Solve Everything", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You have a 128K context window. Your AI still misses key info in the middle. The lost-in-the-middle problem and when RAG beats long context.", excerpt_long: "LLMs attend to start and end of context and underperform on the middle. We cover the research, when long context helps versus when RAG is better, the hybrid approach, and best practices for structuring prompts and retrieval so critical information isn't lost.", read_time: "10 min", date: "Feb 2025", image: "blogs/startup_post_astechware.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "multimodal-ai-pitfalls", path: -> { blog_show_path("multimodal-ai-pitfalls") }, title: "Multi-Modal AI Pitfalls: Lessons from Vision + Language Deployments", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI can 'see' images. So why does it keep missing the invoice total? Preprocessing, OCR-first pipelines, and structured output.", excerpt_long: "Wrong resolution, no fallback when vision fails, and ignoring token costs for images. We cover image preprocessing, when to use OCR then LLM, structured output prompting, and real pipelines for invoice processing, ID verification, and medical imaging—with cost and accuracy in mind.", read_time: "11 min", date: "Feb 2025", image: "ahmad/repi-work.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "synthetic-data-trap", path: -> { blog_show_path("synthetic-data-trap") }, title: "Training AI on AI: The Synthetic Data Trap (And How to Avoid It)", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "You trained your model on AI-generated data. Now it's worse. Model collapse, when synthetic data helps, and mixing strategies that work.", excerpt_long: "Synthetic data promises scale and privacy but model collapse is real—training on AI output degrades models. We cover when synthetic data works (augmentation, rare cases) versus when it fails, mix ratios, validation, and real case studies from customer support and image generation.", read_time: "10 min", date: "Feb 2025", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "testing-ai-systems", path: -> { blog_show_path("testing-ai-systems") }, title: "Testing AI Systems: The Framework Traditional QA Misses", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Your AI passed all tests. Then it told a customer to 'go away.' Non-determinism, adversarial testing, and production monitoring as testing.", excerpt_long: "Traditional unit tests don't catch AI failures. We outline the AI testing framework: prompt regression testing, adversarial and jailbreak testing, evaluation metrics that matter, A/B testing in production, human evaluation, and monitoring as ongoing testing—with examples and tools.", read_time: "11 min", date: "Feb 2025", image: "ahmad/3agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      # Buyer guides & how-to (SEO: best AI agent company, fractional engineering, LangGraph, HIPAA, support automation, production AI)
      { slug: "how-to-evaluate-ai-agent-development-company-2026", path: -> { blog_show_path("how-to-evaluate-ai-agent-development-company-2026") }, title: "How to Evaluate an AI Agent Development Company in 2026", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Choosing the right AI agent development partner: production track record, governance, and what separates the best AI agent companies from demo shops.", excerpt_long: "Not all AI agent companies ship production systems. We break down how to evaluate vendors: proof of production deployments, governance and human-in-the-loop, cost and scaling behavior, and red flags that signal prototype-only teams. A practical checklist for finding the best AI agent company for your use case.", read_time: "9 min", date: "Feb 2025", image: "ahmad/repi-work.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "what-to-look-for-hiring-fractional-engineering-team", path: -> { blog_show_path("what-to-look-for-hiring-fractional-engineering-team") }, title: "What to Look for When Hiring a Fractional Engineering Team", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Fractional engineering teams extend your capacity without full-time hires. What to look for: ownership, communication, and production outcomes.", excerpt_long: "A great fractional engineering team acts as an extension of your team—same standards, clear ownership, and production-ready output. We cover what to look for when hiring: scope and milestones, communication cadence, tech stack fit, and how to tell if they ship or just advise. Plus red flags and how to structure the engagement for success.", read_time: "8 min", date: "Feb 2025", image: "blogs/astechware_new_web_blog_2.webp", author_name: "A'sTechware", author_title: "Platform Engineering" },
      { slug: "building-production-ai-agents-langgraph-complete-guide", path: -> { blog_show_path("building-production-ai-agents-langgraph-complete-guide") }, title: "Building Production AI Agents with LangGraph: Complete Guide", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "LangGraph development for real agents: state graphs, checkpoints, human-in-the-loop, and shipping beyond the tutorial.", excerpt_long: "LangGraph gives you stateful, multi-step agent workflows with cycles and branching—but tutorials stop at the happy path. We cover production LangGraph development: designing state graphs, checkpointing and persistence, error handling and retries, human-in-the-loop nodes, observability, and how we use it for support and triage agents that run in production.", read_time: "12 min", date: "Feb 2025", image: "blogs/turbo_astechware.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "hipaa-compliant-ai-healthcare-companies-guide", path: -> { blog_show_path("hipaa-compliant-ai-healthcare-companies-guide") }, title: "HIPAA Compliant AI: What Healthcare Companies Need to Know", category: "Governance & Compliance", category_slug: "governance-compliance", excerpt_short: "HIPAA AI software requirements: BAA, minimum necessary, audit trails, and how to build AI that fits healthcare compliance.", excerpt_long: "Using AI on PHI means HIPAA applies. We outline what healthcare companies need for HIPAA compliant AI: BAAs with vendors, minimum necessary access, encryption and access controls, audit logging, and how to design agents and RAG so they don't leak or misuse PHI. Practical steps and common gaps that trigger findings.", read_time: "11 min", date: "Feb 2025", image: "ahmad/whatsapp-agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "reduced-customer-support-tickets-90-percent-ai-agents", path: -> { blog_show_path("reduced-customer-support-tickets-90-percent-ai-agents") }, title: "How We Reduced Customer Support Tickets with AI Agents", category: "Case Studies", category_slug: "case-studies", excerpt_short: "AI customer support automation that actually reduces tickets: triage, deflection, and human handoff that scales.", excerpt_long: "We deployed AI agents for customer support that handle FAQs, triage, and escalation—reducing inbound tickets for one client. This case study covers the architecture: knowledge base, confidence thresholds, when to deflect vs escalate, and how we measured impact. What it takes to replicate AI customer support automation that doesn't frustrate users.", read_time: "9 min", date: "Feb 2025", image: "ahmad/3agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "production-ai-vs-prototype-ai-why-projects-fail", path: -> { blog_show_path("production-ai-vs-prototype-ai-why-projects-fail") }, title: "Production AI vs Prototype AI: Why Most AI Projects Fail", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Production AI development is different from demos. Why most AI projects fail—and what it takes to ship systems that last.", excerpt_long: "Demos look great; production breaks. We explain the gap between prototype AI and production AI: reliability, cost at scale, governance, and maintenance. Why most AI projects fail after the pilot, and what production AI development actually requires—monitoring, human-in-the-loop, and treating AI as a product, not a one-off experiment.", read_time: "10 min", date: "Feb 2025", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      # Case studies & existing posts
      { slug: "modular-ai-agents-case-study", path: -> { blog_show_path("modular-ai-agents-case-study") }, title: "Modular AI Agents That Save Time, Scale Outreach, and Automate Support", category: "Case Studies", category_slug: "case-studies", excerpt_short: "Production-ready AI agents for support, voice, and sales outreach—built to plug into your stack with human handoff and full customization.", excerpt_long: "While tools like ChatGPT and Dialogflow excel at demos, real teams need AI that integrates into their tech stack, customizes for support and outreach flows, and maintains human handoff. A'sTechware built modular, production-ready agents for WhatsApp support, voice calls, and cold email that plug into any system and have been battle-tested across healthcare, real estate, and SaaS.", read_time: "8 min", date: "Jun 7, 2024", image: "ahmad/repi-work.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "vestra-app-case-study", path: -> { blog_show_path("vestra-app-case-study") }, title: "Case Study: Vestra.app – Automating Property Management with AI-Powered Simplicity", category: "Case Studies", category_slug: "case-studies", excerpt_short: "How we automated property management workflows with AI, reducing manual work and improving operator experience.", excerpt_long: "Vestra.app needed to move from manual, error-prone property management to an AI-powered platform that could handle scheduling, communications, and operations at scale. We delivered a production system that reduced manual work and improved reliability for property managers and tenants alike.", read_time: "6 min", date: "May 2024", image: "ahmad/3agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "whatsapp-voice-ai-agent-demo", path: -> { blog_show_path("whatsapp-voice-ai-agent-demo") }, title: "WhatsApp & Voice AI Agent Demo: Healthcare Triage & Appointment Booking", category: "AI & Automation", category_slug: "ai-automation", excerpt_short: "Real-time AI agents for WhatsApp and voice that triage, book appointments, and escalate to humans when needed.", excerpt_long: "Healthcare and service businesses need 24/7 responsiveness without burning out staff. We built demo-ready AI agents for WhatsApp and voice that handle triage, appointment booking, and intelligent escalation—with human-in-the-loop so nothing falls through the cracks.", read_time: "5 min", date: "Apr 2024", image: "ahmad/whatsapp-agent.jpeg", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "rails-7-and-turbo", path: -> { blog_show_path("rails-7-and-turbo") }, title: "Exploring the Latest Web Development Trends: A Dive into Rails 7 and Turbo", category: "Technical Deep Dives", category_slug: "technical-deep-dives", excerpt_short: "Why Rails 7 and Turbo matter for fast, maintainable web applications and how we use them in production.", excerpt_long: "Rails 7 and Hotwire Turbo bring faster page updates, less JavaScript, and a simpler mental model for building modern web apps. We break down what's changed and how we're using these tools to ship production applications that stay maintainable over time.", read_time: "7 min", date: "Mar 15, 2023", image: "blogs/turbo_astechware.webp", author_name: "A'sTechware", author_title: "Platform Engineering" },
      { slug: "five-startup-mistakes", path: -> { blog_show_path("five-startup-mistakes") }, title: "Top 5 Startup Mistakes to Avoid: Learn from the Lessons of Others", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Common pitfalls that slow down or sink early-stage products—and how to avoid them with better technical and product choices.", excerpt_long: "After building and rescuing dozens of products, we've seen the same mistakes repeat: scope creep, skipping discovery, hiring the wrong kind of help, and ignoring technical debt. Here’s how to avoid them and keep your startup on track.", read_time: "6 min", date: "Mar 15, 2023", image: "blogs/startup_post_astechware.webp", author_name: "A'sTechware", author_title: "Platform Engineering" },
      { slug: "four-reason-for-new-web", path: -> { blog_show_path("four-reason-for-new-web") }, title: "4 Reasons Why You Should Invest in a New Website", category: "Technical Guides", category_slug: "technical-guides", excerpt_short: "When and why a new website pays off—performance, conversion, security, and credibility.", excerpt_long: "An outdated website costs you leads, trust, and performance. We outline four concrete reasons to invest in a modern site: speed and mobile experience, conversion and analytics, security and compliance, and credibility in a competitive market.", read_time: "4 min", date: "Mar 22, 2023", image: "blogs/astechware_new_web_blog_2.webp", author_name: "A'sTechware", author_title: "Platform Engineering" },
      { slug: "impact-of-ai-ml-on-food-industry", path: -> { blog_show_path("impact-of-ai-ml-on-food-industry") }, title: "The Impact of AI and Machine Learning on the Food Products Business", category: "Industry Solutions", category_slug: "industry-solutions", excerpt_short: "How AI and ML are transforming food production, supply chain, and customer experience—with real use cases.", excerpt_long: "From demand forecasting to quality control and personalized recommendations, AI and machine learning are reshaping the food industry. We explore practical applications and what it takes to implement them in production environments.", read_time: "6 min", date: "Apr 20, 2023", image: "blogs/astechware-food-and-ai-ml.webp", author_name: "A'sTechware", author_title: "AI & Platform Engineering" },
      { slug: "a-laymans-guide-for-hiring-a-top-software-company-in-pakistan", path: -> { blog_show_path("a-laymans-guide-for-hiring-a-top-software-company-in-pakistan") }, title: "A Layman's Guide for Hiring a Top Software Company in Pakistan", category: "Industry Insights", category_slug: "industry-insights", excerpt_short: "Practical advice for non-technical founders on evaluating and selecting a software partner that can deliver.", excerpt_long: "Hiring the right software company is critical for product success. This guide walks through how to evaluate technical partners, what to look for in proposals and teams, and how to avoid common pitfalls when outsourcing development.", read_time: "8 min", date: "Feb 28, 2023", image: "blogs/top_software_company.webp", author_name: "A'sTechware", author_title: "Platform Engineering" }
    ]
  end

  def blog_featured_article
    blog_articles_list.first
  end

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
      "custom-software" => "Custom Software",
      "api-integrations" => "API & Integrations",
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
end
