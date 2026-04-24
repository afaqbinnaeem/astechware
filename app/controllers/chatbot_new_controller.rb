# frozen_string_literal: true

class ChatbotNewController < ApplicationController
  protect_from_forgery except: [:message, :lead]

  require "open3"

  # System prompt used by the "new" chatbot UI (astechware-chatbot.jsx).
  SYSTEM_PROMPT = <<~PROMPT
    You are the AI Consultant for A'sTechware, a production-grade AI and platform engineering company founded by Ahmad Kamran. You are NOT a generic chatbot. You think like Ahmad: practical, production-first, outcome-driven, and deeply technical but always accessible.

    ## YOUR IDENTITY
    - You are "A's AI Consultant", the intelligent front door to A'sTechware
    - You speak with confidence, warmth, and directness, like a senior technical consultant in a discovery call
    - You never say "I'm just an AI" or deflect. You give real, actionable advice.
    - You use "we" when referring to A'sTechware's work and capabilities

    ## COMPANY KNOWLEDGE
    ### About A'sTechware
    - AI and platform engineering partner, 10+ years experience, 50+ projects delivered, 98% client retention
    - Founded by Ahmad Kamran (Founder & CEO), leads strategy, client partnerships, and delivery
    - Contact: ahmad@astechware.com | Calendly: https://calendly.com/ahmadkamran/new-meeting
    - Based on production-first engineering philosophy, we ship systems that work under real operational pressure

    ### Core Services
    1. **AI Agents & Automation**, AI agents, copilots, autonomous workflows with human-in-the-loop, audit trails, observability. We use LangGraph, OpenAI/Anthropic/Gemini, pgvector/Pinecone/Qdrant, LangSmith/Helicone.
    2. **Custom Platform Development**, Full-stack SaaS, internal tools, operations software. React/Next.js/TypeScript/Flutter frontend, Node.js/Python(FastAPI)/Rails backend, PostgreSQL/Redis/MongoDB.
    3. **Platform Modernization & Scaling**, Rescue failing platforms, performance fixes, infrastructure upgrades, CI/CD, observability.
    4. **Integrations & API Engineering**, Connect systems end-to-end (CRMs, billing, scheduling, messaging) with error handling, retry logic, monitoring.

    ### Industries Served
    B2B SaaS, Healthcare & Wellness, Fintech/Financial Services, Real Estate & Operations, Legal Services, Education Technology, Professional Services

    ### Key Metrics & Results
    - 5,127+ tasks automated
    - $2M+ revenue recovered for clients
    - 120+ hours/month saved per client
    - 3-8 weeks typical from kickoff to production deployment

    ### Methodology (The A'sTechware Framework)
    1. Discovery & Pattern Analysis (Week 1), map business, find highest-ROI automation opportunities
    2. Architecture & Security Design (Week 1-2), production-ready architecture with governance
    3. Iterative Development (Weeks 2-6), weekly demos, working software each milestone
    4. Governance Integration (Ongoing), human-in-the-loop, audit trails, RBAC, escalation workflows
    5. Production Deployment, staged rollouts, real-world validation, team training
    6. Continuous Optimization, monitor, gather feedback, iterate on outcomes

    ### How We De-Risk Projects
    - Milestone-based delivery (pay per milestone, not all upfront)
    - Client owns ALL code, infrastructure, documentation from day one, zero lock-in
    - Natural exit points at every milestone, pause/stop anytime without penalties
    - Weekly demos and full visibility
    - Start small with low-risk blueprint before committing big

    ### Past Projects & Case Studies
    **Restaurant Directory Platform (Restaurant Resource)**
    - Challenge: Platform with 1,200+ listings was days from shutting down. Corrupted database, 4,800+ duplicates, broken search, only 12% pages indexed by Google.
    - Solution: Database cleanup, rebuilt semantic search, AI-powered content generation with quality scoring, guided onboarding with human review, review workflows with AI assistance.
    - Results: Traffic 200→4,200 monthly visitors, supplier inquiries 12→85/month, $1,800/month new recurring revenue, platform saved from shutdown.
    - Tech: Rails, PostgreSQL, Elasticsearch, OpenAI APIs, audit logging
    - Client quote: "Ahmad has been an exceptional contractor and we feel incredibly fortunate to have found him.", Brianne Harvey, Founder

    **Golf Course SaaS Platform (Golfpay)**
    - Challenge: Build end-to-end SaaS for golf operations. Only 15% bookings online, staff overwhelmed by phone volume, no dynamic pricing.
    - Solution: Web & mobile tee-time booking, member/loyalty management, POS for pro shop & F&B, tournament management, 24/7 AI phone receptionist with human escalation, dynamic pricing engine.
    - Tech: Full-stack platform with AI integration
    - Client: Dale Merritt, CEO, "One of the most reliable developers I've had the pleasure to have."

    **Healthcare AI Assistant (Wellness Clinic)**
    - Challenge: 5,000+ patient inquiries monthly, staff overwhelmed, no-shows bleeding revenue.
    - Solution: AI agent for appointment scheduling, FAQs, triage with HIPAA-compliant messaging and human escalation.
    - Results: 5,127 tickets auto-resolved in 90 days, no-shows dropped 35%→6%, recovered ~$28K/month revenue.

    ### Other Notable Clients
    Vestra Software Solutions (US), Word of Mouth Online (Australia), Zoficash, The Grants Hub, DriftGolf, Selland Technologies, ZidZid, Instashowing, SWS, Warcoconstruction

    ## YOUR BEHAVIOR
    ### How to Advise on AI/ML/Automation
    When someone describes their business or operations, you should:
    1. **Listen carefully** to their pain points, workflows, and bottlenecks
    2. **Identify specific opportunities** where AI, ML, or automation would have the highest ROI
    3. **Explain concretely** what an AI/automation solution would look like for THEIR specific case
    4. **Reference relevant past projects** when applicable (e.g., if they're in healthcare, mention the wellness clinic case)
    5. **Quantify potential impact** using realistic estimates based on our past results
    6. **Think like Ahmad**, production-first, governance-aware, milestone-based, outcome-driven

    ### Lead Capture Strategy
    After providing valuable advice (NOT before), naturally transition to collecting contact info:
    - First give genuine, specific, actionable advice about their business
    - Then say something like: "I'd love to have Ahmad and the team dig deeper into this with you. Want to leave your contact info so we can set up a proper discovery call?"
    - Collect: Name, Email, Company/Business name, and optionally Phone number
    - Always offer the Calendly link too: https://calendly.com/ahmadkamran/new-meeting
    - NEVER be pushy. Be helpful first, capture leads naturally.

    ### IMPORTANT RULES
    - Always be helpful FIRST. Lead capture is secondary to providing genuine value.
    - Never make up case studies or metrics. Only reference the ones provided above.
    - If someone asks about pricing, say it depends on scope and complexity, suggest a discovery call to discuss specifics. We work milestone-based.
    - Keep responses concise and conversational: typically 3-4 short paragraphs unless they ask for more detail.
  PROMPT

  def message
    user_message = params[:message].to_s
    if user_message.blank?
      render json: { error: "Message cannot be blank" }, status: :bad_request
      return
    end

    if recaptcha_enabled_for_chat? && !session[:chatbot_new_recaptcha_passed]
      recaptcha_token = params[:recaptcha_token] || params["g-recaptcha-response"]
      verification = RecaptchaVerificationService.verify(
        recaptcha_token,
        request.remote_ip,
        expected_action: 'chat'
      )
      unless verification[:success]
        render json: { error: "reCAPTCHA verification failed. Please try again." }, status: :unprocessable_entity
        return
      end
      session[:chatbot_new_recaptcha_passed] = true
    end

    history = normalize_history(params[:history])
    include_history = ENV.fetch("CHATBOT_INCLUDE_HISTORY", "true").to_s.downcase == "true"
    history = [] unless include_history

    begin
      chat_session = find_or_create_chat_session!
      request_id = SecureRandom.uuid

      chat_session.chat_messages.create!(
        role: "user",
        content: user_message,
        provider: "web",
        request_id: request_id
      )

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = run_pipeline_backend(user_message: user_message, history: history)
      latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000.0).round
      ai_message = result["answer_markdown"].to_s

      if ai_message.blank?
        raise "Pipeline returned blank answer_markdown"
      end

      chat_session.chat_messages.create!(
        role: "assistant",
        content: ai_message,
        provider: "pipeline",
        request_id: request_id,
        latency_ms: latency_ms,
        meta: result
      )

      chat_session.update!(last_message_at: Time.current)

      render json: {
        message: ai_message,
        answer_style: result["answer_style"],
        citations: Array(result["citations"]),
        suggestions: Array(result["suggestions"]),
        confidence: result["confidence"],
        needs_clarification: result["needs_clarification"],
        clarifying_question: result["clarifying_question"],
        commercial_flags: result["commercial_flags"],
        request_id: request_id,
        error: nil
      }
    rescue StandardError => e
      # Fallback to the previous OpenAI-backed behavior if the Python pipeline fails.
      Rails.logger.error "ChatbotNewController pipeline failed: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
      ai_message = legacy_openai_chat(user_message: user_message, history: history)

      begin
        chat_session = find_or_create_chat_session!
        request_id = SecureRandom.uuid
        chat_session.chat_messages.create!(
          role: "user",
          content: user_message,
          provider: "web",
          request_id: request_id
        )
        chat_session.chat_messages.create!(
          role: "assistant",
          content: ai_message,
          provider: "openai_fallback",
          request_id: request_id,
          meta: { error: "#{e.class}: #{e.message}" }
        )
        chat_session.update!(last_message_at: Time.current)
      rescue StandardError => persist_err
        Rails.logger.error "Chat persistence failed: #{persist_err.class}: #{persist_err.message}"
      end

      render json: {
        message: ai_message,
        citations: [],
        suggestions: [],
        error: nil
      }
    end
  rescue StandardError => e
    Rails.logger.error "ChatbotNewController#message error: #{e.class}: #{e.message}"
    render json: { error: "Failed to get response from AI. Please try again later.", message: e.message }, status: :internal_server_error
  end

  def history
    chat_session = find_or_create_chat_session!
    messages = chat_session.chat_messages.order(:created_at).limit(200)

    payload = messages.map do |m|
      {
        role: m.role,
        content: m.content,
        meta: m.meta,
        created_at: m.created_at
      }
    end

    render json: { messages: payload, error: nil }
  rescue StandardError => e
    Rails.logger.error "ChatbotNewController#history error: #{e.class}: #{e.message}"
    render json: { messages: [], error: "Failed to load history" }, status: :internal_server_error
  end

  def lead
    lead = params[:lead].respond_to?(:to_unsafe_h) ? params[:lead].to_unsafe_h : params[:lead].to_h
    name = lead["name"].to_s.strip
    email = lead["email"].to_s.strip.downcase
    company_name = lead["company"].to_s.strip
    _phone = lead["phone"].to_s.strip

    if name.blank? || email.blank? || company_name.blank?
      render json: { error: "Name, email, and company are required" }, status: :unprocessable_entity
      return
    end

    unless email.match?(/\A\S+@\S+\.\S+\z/)
      render json: { error: "Valid email is required" }, status: :unprocessable_entity
      return
    end

    history = normalize_history(params[:history])
    last_user_message = history.reverse.find { |m| m["role"] == "user" }&.fetch("content", nil).to_s

    conversation_summary = nil
    if ENV["OPENAI_API_KEY"].present?
      begin
        conversation_summary = ConversationSummaryGenerator.generate(
          conversation_history: history,
          current_message: last_user_message.presence || name
        )
      rescue StandardError => e
        Rails.logger.error "ChatbotNewController#lead summary error: #{e.message}"
      end
    end

    description = conversation_summary.presence || last_user_message.presence || "Lead submitted from chat widget"

    ChatLeadMailer.notify_lead(
      contact_info: {
        name: name,
        email: email,
        company_name: company_name,
        description: description
      },
      conversation_summary: conversation_summary
    ).deliver

    message = "Thanks, #{name}! I've noted your details, Ahmad will personally reach out to you at **#{email}** within 24 hours to discuss how we can help #{company_name}."

    render json: { message: message, error: nil }
  rescue StandardError => e
    Rails.logger.error "ChatbotNewController#lead error: #{e.message}"
    render json: { error: "Failed to submit lead", message: e.message }, status: :internal_server_error
  end

  private

  def normalize_history(history_param)
    return [] unless history_param.present? && history_param.is_a?(Array)

    valid_history = history_param.map do |msg|
      msg_hash = msg.is_a?(ActionController::Parameters) ? msg.to_unsafe_h : msg.to_h
      msg_hash
    end.select do |msg_hash|
      msg_hash.is_a?(Hash) &&
        msg_hash["role"].present? &&
        msg_hash["content"].present? &&
        %w[user assistant].include?(msg_hash["role"])
    end

    # Keep only last 5 messages to bound token usage
    valid_history.length > 5 ? valid_history.last(5) : valid_history
  end

  def find_or_create_chat_session!
    visitor_id = current_chat_visitor_id
    Rails.logger.info("visitor id: #{visitor_id}")
    ChatSession.find_or_create_by!(visitor_id: visitor_id) do |s|
      s.status = "open"
      s.last_message_at = Time.current
      s.metadata = {
        user_agent: request.user_agent,
        referrer: request.referer,
        landing_path: request.fullpath
      }.compact
    end
  end

  def current_chat_visitor_id
    cookie_key = :astechware_chat_visitor_id
    existing = cookies.signed[cookie_key].to_s
    return existing if existing.present?

    new_id = SecureRandom.uuid
    cookies.signed[cookie_key] = {
      value: new_id,
      expires: 1.year.from_now,
      httponly: true,
      same_site: :lax
    }
    new_id
  end

  def recaptcha_enabled_for_chat?
    # Same gating rule as the contact form: only enable if keys are configured.
    (ENV["RECAPTCHA_SITE_KEY"].present? || Rails.application.credentials.dig(:recaptcha, :site_key).present?) &&
      (ENV["RECAPTCHA_SECRET_KEY"].present? || Rails.application.credentials.dig(:recaptcha, :secret_key).present?)
  end

  def run_pipeline_backend(user_message:, history:)
    script_path = Rails.root.join("cursor-final-pipeline1-1.py").to_s

    history_text =
      history
        .last(5)
        .map { |m| "#{m["role"]}: #{m["content"]}" }
        .join("\n")

    question =
      if history_text.present?
        "Conversation so far:\n#{history_text}\n\nUser question:\n#{user_message}"
      else
        user_message.to_s
      end

    stdin_payload = {
      question: question,
      # Pipeline long-input guard counts words on this only (not conversation + history prefix).
      current_user_message: user_message.to_s
    }.to_json

    python_cmds = []
    explicit = ENV["CHATBOT_NEW_PYTHON_CMD"].to_s.strip
    python_cmds << explicit if explicit.present?
    python_cmds.concat(%w[python3 python])
    python_cmds.uniq!

    last_error = nil

    python_cmds.each do |cmd|
      stdout, stderr, status = Open3.capture3(
        { "PYTHONUNBUFFERED" => "1" },
        cmd,
        script_path,
        chdir: Rails.root.to_s,
        stdin_data: stdin_payload
      )

      # Forward pipeline logs into container logs.
      # (Open3.capture3 captures stderr instead of streaming it.)
      if stderr.present?
        Rails.logger.info("[chatbot_pipeline][#{cmd}] #{stderr}")
      end

      if status.success?
        parsed = JSON.parse(stdout.to_s)
        return parsed.is_a?(Hash) ? parsed : { "answer_markdown" => "" }
      end

      last_error = "cmd=#{cmd} exit=#{status.exitstatus} stderr=#{stderr.to_s}"
    end

    raise "Python pipeline failed to run: #{last_error}"
  end

  def legacy_openai_chat(user_message:, history:)
    api_key = ENV["OPENAI_API_KEY"]
    if api_key.blank?
      raise "OpenAI API key not configured"
    end

    model = ENV["OPENAI_MODEL_NEW"] || ENV["OPENAI_MODEL"] || "gpt-4o-mini"
    client = OpenAI::Client.new(access_token: api_key)

    messages = [{ role: "system", content: SYSTEM_PROMPT }]
    messages.concat(history)
    messages << { role: "user", content: user_message }

    response = client.chat(
      parameters: {
        model: model,
        messages: messages,
        temperature: 0.7,
        max_tokens: 1000
      }
    )

    ai_message = response.dig("choices", 0, "message", "content").to_s
    if ai_message.blank?
      raise "No response from AI"
    end

    ai_message
  end
end

