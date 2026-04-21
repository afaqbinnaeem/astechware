"""
═══════════════════════════════════════════════════════════════
A'sTechware — Production RAG Pipeline V2 (A'sTechware Site-wide)
═══════════════════════════════════════════════════════════════

PIPELINE V2 FLOW:
  User Question
    → Stage 0: Long-input guard (>500 words on the current user message → recommend technical call;
      full conversation may be appended separately — guard does not sum prior turns)
    → Stage 1: AI Router (greeting / out_of_scope / rag_only / web_only / rag_plus_web)
    → Stage 1b: Contact info shortcut (Ahmad email / phone → direct answer, overrides router)
    → Stage 2: Route handling
       - greeting      → direct response
       - out_of_scope  → direct redirect response
       - rag_only      → existing RAG pipeline
       - web_only      → web route stub (ready for future live web integration)
       - rag_plus_web  → web + RAG route stub (ready for future live web integration)

RAG FLOW (kept from your existing pipeline):
  → Step 1:  Classify the question (site-wide services + industries)
  → Step 2:  Build smart filters
  → Step 3:  Embed the question
  → Step 4:  Hybrid search in Supabase (Vector + FTS/BM25-ish)
  → Step 5:  Fuse + Re-rank results
  → Step 6:  Fetch related chunks + build context
  → Step 7:  Generate structured answer (with policy rules)
  → Step 8:  Enrich citations + validate answer
  → Step 9:  Handle fallback if no good match

REQUIRES SUPABASE RPC FUNCTIONS:
  - match_chunks_vector
  - match_chunks_fts

INSTALL:
  pip install openai supabase python-dotenv
═══════════════════════════════════════════════════════════════
"""

import os
import re
import json
import time
import sys
from contextlib import contextmanager
from typing import List, Dict, Any, Optional

from dotenv import load_dotenv
from openai import OpenAI
from supabase import create_client


# ─────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────
# Keep stdout reserved for machine-readable JSON (used by Rails).
# Send all debug logs to stderr so they show up in docker logs without
# breaking JSON parsing.
def log(*args, **kwargs):
    kwargs.setdefault("file", sys.stderr)
    kwargs.setdefault("flush", True)
    print(*args, **kwargs)


# ─────────────────────────────────────────────────────────────
# TIMING (stderr only — stdout stays JSON for Rails)
# ─────────────────────────────────────────────────────────────
_PIPELINE_T0: Optional[float] = None


def pipeline_timer_reset() -> None:
    """Call once at process entry (CLI) to anchor cumulative ms."""
    global _PIPELINE_T0
    _PIPELINE_T0 = time.perf_counter()


def pipeline_elapsed_ms() -> float:
    if _PIPELINE_T0 is None:
        return 0.0
    return (time.perf_counter() - _PIPELINE_T0) * 1000.0


def log_timing(step: str, detail: str = "", step_ms: Optional[float] = None) -> None:
    """step_ms: duration of just this segment (e.g. one OpenAI call)."""
    extra = f" | {detail}" if detail else ""
    if step_ms is not None:
        log(
            f"[pipeline_timing] +{pipeline_elapsed_ms():.1f}ms cumulative | {step}{extra} | step={step_ms:.1f}ms"
        )
    else:
        log(f"[pipeline_timing] +{pipeline_elapsed_ms():.1f}ms cumulative | {step}{extra}")


@contextmanager
def time_block(label: str, detail: str = ""):
    t0 = time.perf_counter()
    yield
    ms = (time.perf_counter() - t0) * 1000.0
    log_timing(label, detail=detail, step_ms=ms)


# ─────────────────────────────────────────────────────────────
# ENV LOADING
# ─────────────────────────────────────────────────────────────
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
SUPABASE_URL   = os.getenv("SUPABASE_URL")
SUPABASE_KEY   = os.getenv("SUPABASE_KEY")
JSON_FILE      = os.getenv("JSON_FILE")
CHAT_BOT_OPENAI_MODEL = os.getenv("CHAT_BOT_OPENAI_MODEL") or "gpt-4.1-nano"


def require_env(name: str, value: Optional[str]) -> str:
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


OPENAI_API_KEY = require_env("OPENAI_API_KEY", OPENAI_API_KEY)
SUPABASE_URL   = require_env("SUPABASE_URL", SUPABASE_URL)
SUPABASE_KEY   = require_env("SUPABASE_KEY", SUPABASE_KEY)

openai_client   = OpenAI(api_key=OPENAI_API_KEY)
supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ─────────────────────────────────────────────────────────────
# CONFIG / THRESHOLDS
# ─────────────────────────────────────────────────────────────
HIGH_CONFIDENCE   = 0.75
MEDIUM_CONFIDENCE = 0.55
LOW_CONFIDENCE    = 0.40
TOP_K             = 5
SEARCH_K          = TOP_K + 3

# NEW: simple business rule for long pasted briefs
LONG_INPUT_WORD_LIMIT = 500

VALID_TAXONOMY_KEYS = [
    "ai_agents_automation",
    "custom_platform_development",
    "platform_modernization_scaling",
    "integrations_api_engineering",
    "healthcare_solution",
    "fintech_solution",
    "legal_solution",
    "b2b_saas_solution",
]

VALID_SUGGESTION_TYPES = ["service", "case_study", "question", "meeting"]

ALL_CATEGORIES = [
    "company", "service_capability", "challenge",
    "compliance", "case_study", "faq", "general", "unknown", "blog"
]

MASTER_TOPICS = [
    # ── Company / General ─────────────────────────────
    "overview", "about", "team", "company", "mission", "values",
    "methodology", "delivery", "milestones", "ownership",
    "results", "metrics", "why-choose-us", "transparency",

    # ── Services ──────────────────────────────────────
    "ai-agents", "automation", "copilot", "workflow-automation",
    "llm", "generative-ai", "multi-agent",
    "custom-software", "saas-platform", "platform-modernization",
    "api-integrations", "devops", "governance", "observability",
    "engineering-rescue", "idempotency", "circuit-breaker",
    "dead-letter-queue", "webhook", "event-streaming",
    "data-sync", "edi",

    # ── Tech stack ────────────────────────────────────
    "react", "nextjs", "python", "nodejs", "postgresql",
    "aws", "gcp", "azure", "langchain", "langgraph",
    "openai", "anthropic", "pgvector", "pinecone",
    "stripe", "auth0", "hubspot", "salesforce", "kubernetes",
    "docker", "terraform", "selenium", "elasticsearch",
    "weaviate", "tensorflow", "pytorch",

    # ── Industries ────────────────────────────────────
    "b2b-saas", "fintech", "legal", "real-estate",
    "edtech", "professional-services", "saas-platform", "multi-tenancy",
    "billing-subscription", "feature-velocity", "mvp",
    "engineering-capacity", "technical-debt", "lead-quality",
    "payments", "lending", "fraud-detection", "kyc-aml",
    "lms", "student-engagement",
    "student-analytics", "content-delivery",
    "accessibility", "logistics", "dispatch", "route-optimization",
    "field-operations", "proof-of-service", "customer-communication",
    "contract-review", "legal-research", "document-automation",
    "matter-management", "ediscovery", "litigation", "iolta",
    "billing", "client-intake", "client-portal", "client-communication",
    "attorney-client-privilege", "legal-ethics", "document-management",

    # ── Healthcare ────────────────────────────────────
    "ai-scheduling", "patient-intake", "hipaa", "hitech",
    "42-cfr-part-2", "telehealth", "ehr-integration",
    "fhir", "hl7", "compliance", "baa", "phi",
    "no-shows", "revenue-cycle", "patient-portal",
    "clinical-workflow", "multi-location",
    "epic", "cerner", "athenahealth", "admin-burden",
    "security",

    # ── Pricing / engagement ──────────────────────────
    "pricing", "implementation", "ongoing-support",
    "case-study", "data-migration",

    "voice-ai", "clinical-triage", "ai-medical-scribe",
    "ocr", "pdf-generation", "litigation-support",
    "private-ai", "marketplace", "legacy-migration",
    "zero-downtime", "catalog-search", "database-rescue",
    "high-concurrency", "multi-tenant", "booking",
    "field-ops", "webhooks", "ledgering", "earned-wage-access",
    "payroll", "search",
    "martech",
    "digital-marketing",
    "ad-automation",
    "social-media-automation",
    "meta-ads",
    "google-ads",

    # ── Blog topics (matched to actual blog chunk topic values) ───
    "production-ai",              # used across multiple blog chunks
    "chatbot",                    # blog-ai-chatbot-death-spiral-*
    "monitoring",                 # chatbot + cost blogs
    "feedback-loops",             # chatbot death spiral
    "accuracy-drift",             # chatbot death spiral
    "prompt-iteration",           # chatbot fix-loop
    "human-in-the-loop",          # agentic AI, langgraph, testing
    "cost-optimization",          # ai-cost-explosion, fine-tuning
    "model-routing",              # ai-cost-explosion
    "semantic-caching",           # ai-cost-explosion
    "token-efficiency",           # ai-cost-explosion
    "vendor-evaluation",          # evaluate-ai-agent-company, fractional-engineering
    "prompt-injection",           # prompt-injection blog
    "tool-safety",                # prompt-injection
    "least-privilege",            # prompt-injection controls
    "audit-trails",               # prompt-injection, agentic-ai, hipaa
    "rag",                        # rag-mistakes, hipaa-rag, context-window
    "chunking",                   # rag-mistakes
    "retrieval",                  # rag-mistakes
    "reranking",                  # rag-mistakes, context-window
    "hallucinations",             # rag-mistakes
    "metadata",                   # rag-mistakes
    "fallbacks",                  # rag-mistakes, langgraph
    "retrieval-design",           # rag-mistakes best practices
    "agentic-ai",                 # agentic-ai-governance
    "approval-flows",             # agentic-ai-governance
    "automation-risk",            # agentic-ai-governance
    "staged-autonomy",            # agentic-ai-governance pattern
    "tool-permissions",           # agentic-ai-governance pattern
    "fine-tuning",                # fine-tuning-vs-prompting
    "prompt-engineering",         # fine-tuning-vs-prompting
    "latency",                    # fine-tuning-vs-prompting
    "model-strategy",             # fine-tuning-vs-prompting
    "ownership",                  # evaluate-company, fractional-engineering
    "langgraph",                  # langgraph production agents
    "agent-orchestration",        # langgraph
    "state-management",           # langgraph
    "checkpointing",              # langgraph pattern
    "retries",                    # langgraph pattern
    "auditability",               # langgraph pattern
    "healthcare-ai",              # hipaa blog
    "minimum-necessary",          # hipaa blog
    "role-based-access",          # hipaa rag-agent-risks
    "patient-scoped-retrieval",   # hipaa rag-agent-risks
    "context-window",             # lost-in-middle blog
    "lost-in-the-middle",         # lost-in-middle blog
    "retrieval-ordering",         # lost-in-middle blog
    "ai-testing",                 # testing-ai-systems
    "non-determinism",            # testing-ai-systems
    "adversarial-testing",        # testing-ai-systems
    "evals",                      # testing-ai-systems
    "prototype-vs-production",    # production-ai-vs-prototype
    "fractional-engineering",     # fractional-engineering-team
    "handoff",                    # fractional-engineering
    "execution-capacity",         # fractional-engineering
    "customer-support-automation", # reduced-support-tickets
    "ticket-deflection",          # reduced-support-tickets
    "operations-metrics",         # reduced-support-tickets
]

TOPIC_NORMALIZATION = {
    "scheduling": "ai-scheduling",
    "patient-intake-form": "patient-intake",
    "waitlist": "waitlist-management",
    "mobile": "mobile-app",
    "audit-logging": "audit-trails",
    "wellness": "wellness-clinic",
    "remote-care": "telehealth",
    "hipaa-messaging": "patient-communication",
    "fraud": "fraud-detection",
    "kyc": "kyc-aml",
    "aml": "kyc-aml",
    "payments": "payments",
    "education": "edtech",
    "learning-management": "lms",
    "elearning": "lms",
    "e-learning": "lms",
    "routing": "route-optimization",
    "hvac": "field-operations",
    "dispatching": "dispatch",
    "proof-of-delivery": "proof-of-service",
    "contracts": "contract-review",
    "due-diligence": "contract-review",
    "e-discovery": "ediscovery",
    "trust-accounting": "iolta",
    "afa": "billing",
    "flat-fee": "billing",
    "intake": "client-intake",
    "matter-tracking": "matter-management",
    "rescue": "engineering-rescue",
    "platform-rescue": "engineering-rescue",
    "agency-rescue": "engineering-rescue",
    "dlq": "dead-letter-queue",
    "idempotent": "idempotency",
    "circuit breaker": "circuit-breaker",
    "webhooks": "webhook",
    "event-driven": "event-streaming",
    "kafka": "event-streaming",
    "sync": "data-sync",
    "bidirectional sync": "data-sync",
    "edi x12": "edi",
    "sftp integration": "api-integrations",
    "voice agent": "voice-ai",
    "voice bot": "voice-ai",
    "ambient scribe": "ai-medical-scribe",
    "medical scribe": "ai-medical-scribe",
    "ehr sync": "ehr-integration",
    "athena sync": "athenahealth",
    "multi tenant": "multi-tenant",
    "marketplace rescue": "platform-modernization",
    "legacy rewrite": "legacy-migration",
    "zero downtime migration": "zero-downtime",
    "search rescue": "database-rescue",
    "catalog": "catalog-search",
    "split payments": "payments",
    "stripe connect": "payments",
    "ewa": "earned-wage-access",
    "salary advance": "earned-wage-access",
    "route planning": "route-optimization",
    "proof of service": "proof-of-service",
    "proof-of-work": "proof-of-service",
    # ── Blog topic aliases ─────────────────────────────────────────
    # chatbot death spiral
    "chatbot degradation": "accuracy-drift",
    "chatbot accuracy": "accuracy-drift",
    "chatbot drift": "accuracy-drift",
    "demo vs production": "production-ai",
    "production chatbot": "chatbot",
    "chatbot monitoring": "monitoring",
    "ai monitoring": "monitoring",
    # cost explosion
    "llm cost": "cost-optimization",
    "ai cost": "cost-optimization",
    "token optimization": "token-efficiency",
    "model selection": "model-routing",
    "caching": "semantic-caching",
    # prompt injection
    "prompt attack": "prompt-injection",
    "ai security": "prompt-injection",
    "injection attack": "prompt-injection",
    # rag mistakes
    "rag implementation": "rag",
    "rag pipeline": "rag",
    "rag accuracy": "rag",
    "chunk size": "chunking",
    "embedding strategy": "retrieval",
    # agentic ai
    "agent safety": "agentic-ai",
    "ai agent governance": "agentic-ai",
    "autonomous ai": "agentic-ai",
    "agentic governance": "agentic-ai",
    "tool permissions": "tool-permissions",
    "permission scoping": "least-privilege",
    # fine tuning
    "fine tuning": "fine-tuning",
    "finetuning": "fine-tuning",
    "custom model": "fine-tuning",
    "when to fine tune": "fine-tuning",
    # vendor evaluation
    "choose ai company": "vendor-evaluation",
    "evaluate agency": "vendor-evaluation",
    "ai partner": "vendor-evaluation",
    # langgraph
    "langgraph guide": "langgraph",
    "agent orchestration": "agent-orchestration",
    "state graph": "state-management",
    # hipaa ai
    "hipaa compliant ai": "healthcare-ai",
    "ai hipaa": "healthcare-ai",
    "phi handling": "minimum-necessary",
    # context window
    "context length": "context-window",
    "large context": "context-window",
    "lost in the middle": "lost-in-the-middle",
    # testing
    "ai qa": "ai-testing",
    "ai evaluation": "evals",
    "llm testing": "ai-testing",
    "non deterministic": "non-determinism",
    # production ai
    "prototype vs production": "prototype-vs-production",
    "production failure": "production-ai",
    "why ai projects fail": "production-ai",
    # fractional engineering
    "fractional team": "fractional-engineering",
    "fractional cto": "fractional-engineering",
    "contract engineers": "fractional-engineering",
    # support automation
    "support ticket reduction": "ticket-deflection",
    "ai customer support": "customer-support-automation",
    "deflect tickets": "ticket-deflection",
    "facebook ads": "meta-ads",
    "google ads": "google-ads",
    "meta ads": "meta-ads",
    "ad campaigns": "ad-automation",
    "social media automation": "social-media-automation",
    "instagram ads": "meta-ads",
    "paid ads": "ad-automation",
    "paid social": "meta-ads",
}


def normalize_topics(topics: list) -> list:
    normalized = []
    for topic in topics or []:
        normalized.append(TOPIC_NORMALIZATION.get(topic, topic))
    return list(dict.fromkeys(normalized))


def pretty_topic_label(topic: str) -> str:
    """
    Make topics look nicer in mixed-scope notes.
    HIPAA/FHIR/HL7 stay uppercase.
    """
    if not topic:
        return ""

    upper_terms = {
        "hipaa", "fhir", "hl7", "edi", "phi", "mfa", "baa",
        "kyc", "aml", "pci", "ach", "rtp", "ofac", "sar", "ctr",
        "ferpa", "coppa", "scorm", "xapi", "lti", "lms",
        "wcag", "sis", "nlp"
    }
    if topic.lower() in upper_terms:
        return topic.upper()

    return topic.replace("-", " ")


# ═══════════════════════════════════════════════════════════════
# STAGE 0 — LONG INPUT GUARD
# Simple business rule: >500 words = recommend call
# ═══════════════════════════════════════════════════════════════

def count_words(text: str) -> int:
    return len((text or "").strip().split())


def should_escalate_long_input(text: str) -> bool:
    return count_words(text) > LONG_INPUT_WORD_LIMIT


def handle_long_input_escalation() -> dict:
    message = (
        "This looks like a detailed project brief rather than a simple site question. A'sTechware likely can help, but "
        "For something this detailed, the best next step is usually a 30-minute technical call "
        "so A'sTechware can give useful guidance without missing important context.\n\n"
        "If you want, I can still help in chat by answering one focused question about it — for example:\n"
        "- Is A'sTechware a fit for this?\n"
        "- Which service is the best match?\n"
        "- Are there relevant case studies?\n"
        "- What are the main technical risks?"
    )

    return {
        "answer_markdown": message,
        "answer_style": "direct",
        "citations": [],
        "suggestions": [
            {
                "type": "meeting",
                "label": "Book a 30-Min Technical Call",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "Is A'sTechware a fit for this use case?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "Which A'sTechware service best matches this project?",
                "taxonomy_key": None
            }
        ],
        "confidence": 0.95,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {
            "meeting_recommended": True,
            "reason": "input_over_500_words",
            "priority": "high_intent"
        }
    }


# ═══════════════════════════════════════════════════════════════
# STAGE 1 — AI ROUTER (FIRST AI CALL)
# ═══════════════════════════════════════════════════════════════

ROUTER_ALLOWED_INDUSTRIES = [
    "b2b-saas",
    "healthcare",
    "financial",
    "professional-services",
    "legal",
    "education-technology"
]

ROUTER_ALLOWED_TOPICS = [
    "ai-agents",
    "automation",
    "custom-software",
    "platform-modernization",
    "api-integrations",
    "case-studies",
    "pricing",
    "compliance",
    "hipaa",
    "fhir",
    "hl7",
    "ehr-integration",
    "engineering-rescue",
    "de-risking",
    "technical-review",
    "website-analysis",
     "martech",
    "digital-marketing",
    "ad-automation",
]

VALID_ROUTES = {
    "greeting",
    "out_of_scope",
    "rag_only",
    "rag_plus_web"
}


def build_router_prompt(user_input: str) -> str:
    return f"""
You are a router for A'sTechware — an AI & product engineering company.
They build: AI agents, custom SaaS, platform modernization, integrations, and marketing automation.
Industries: b2b-saas, healthcare, fintech, legal, education, professional-services.

Return ONLY JSON with "route" as one of:
- "greeting"     → pure smalltalk (hi, thanks, bye)
- "out_of_scope" → unrelated to software/AI/engineering
- "rag_only"     → questions about A'sTechware services, case studies, pricing, team, fit
- "rag_plus_web" → user shares a URL and wants A'sTechware to assess/compare it

Routing rules:
- Any business question (even if it starts with "hi") → rag_only, NOT greeting
- If the input includes a "Conversation so far:" transcript, route from the **latest** user intent (follow-ups,
  topic changes like healthcare → fintech, typo corrections) → almost always rag_only, not out_of_scope
- URL present + asking about fit/build/improve/assess/compare → rag_plus_web
- Trust, credibility, compliance, pricing, case study, or delivery questions → rag_only
- Questions asking for Ahmad’s email, A'sTechware contact email, phone number, WhatsApp, how to reach the founder, or general contact info → rag_only (NOT out_of_scope)
- Vague but in-scope → rag_only with needs_clarification=true
- Prefer rag_only unless clearly out-of-scope

Return ONLY:
{{"route":"...", "greeting_message":"", "query_type":"...", "topics":[], "industries":[], "has_url":false, "needs_clarification":false, "reason":""}}

If route=="greeting", set greeting_message to 1-2 short sentences mentioning A'sTechware.

User: {user_input}
""".strip()

def route_query(user_input: str) -> dict:
    prompt = build_router_prompt(user_input)

    try:
        t_ai = time.perf_counter()
        response = openai_client.chat.completions.create(
            model=CHAT_BOT_OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"}
        )
        log_timing(
            "openai_chat",
            detail="router model=gpt-4.1-nano",
            step_ms=(time.perf_counter() - t_ai) * 1000.0,
        )

        data = json.loads(response.choices[0].message.content)

        if data.get("route") not in VALID_ROUTES:
            data["route"] = "rag_only"

        return {
            "route": data.get("route", "rag_only"),
            "greeting_message": data.get("greeting_message", "") or "",
            "query_type": data.get("query_type", "service_capability"),
            "topics": data.get("topics", []),
            "industries": data.get("industries", []),
            "has_url": data.get("has_url", False),
            "needs_clarification": data.get("needs_clarification", False),
            "reason": data.get("reason", "")
        }

    except Exception as e:
        log(f"  → Router failed, defaulting to rag_only: {e}")
        return {
            "route": "rag_only",
            "greeting_message": "",
            "query_type": "service_capability",
            "topics": [],
            "industries": [],
            "has_url": False,
            "needs_clarification": False,
            "reason": "router_fallback"
        }


def handle_greeting_route(router_result: Optional[dict] = None) -> dict:
    router_result = router_result or {}
    greeting_message = (router_result.get("greeting_message") or "").strip()
    if not greeting_message:
        greeting_message = (
            "A'sTechware builds AI agents, custom platforms, and integrations "
            "for businesses that need production-grade software without a full in-house team. "
            "What are you looking to build?"
        )
    return {
        "answer_markdown": (
            greeting_message
        ),
        "answer_style": "direct",
        "citations": [],
        "suggestions": [
            {
                "type": "question",
                "label": "What services does A'sTechware offer?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "Do you have relevant case studies?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "Can A'sTechware build something like my product?",
                "taxonomy_key": None
            }
        ],
        "confidence": 0.95,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {}
    }


def handle_out_of_scope_route() -> dict:
    return {
        "answer_markdown": (
            "I’m here to help with A'sTechware’s services, case studies, technical fit, and delivery approach. "
            "If you’re exploring a software, AI, automation, platform, or integration need, tell me what you’re trying to build and I’ll point you in the right direction."
        ),
        "answer_style": "direct",
        "citations": [],
        "suggestions": [
            {
                "type": "question",
                "label": "Do you have case studies for AI agents or automation?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "What’s the best case study you have in my industry?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "What does A'sTechware specialize in?",
                "taxonomy_key": None
            }
        ],
        "confidence": 0.90,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {}
    }


# Public contact details (must match site / RAG). Used when users ask for email or phone directly.
PUBLIC_CONTACT_EMAIL = "ahmad@astechware.com"
PUBLIC_CONTACT_PHONE_DISPLAY = "(888) 348-8752"
PUBLIC_CONTACT_PHONE_RAW = "8883488752"


def contact_info_intent(user_input: str) -> Optional[str]:
    """
    Returns 'email', 'phone', or 'both' when the user is asking for Ahmad / A'sTechware
    contact details — not technical topics like 'email integration'.

    """
    t = (user_input or "").strip().lower()
    if not t:
        return None

    if re.search(r"\bemail\s+(integration|notifications?|ingestion|workflow|parser|routing)\b", t):
        return None

    email_hit = bool(
        re.search(r"\b(e-?mail|email)\s+(of|for)\s+ahmad\b", t)
        or (re.search(r"\bahmad\b", t) and re.search(r"\b(e-?mail|email)\b", t))
        or re.search(r"\b(send|give|share)\b.{0,40}\b(e-?mail|email)\b.{0,40}\bahmad\b", t)
        or re.search(r"\bahmad\b.{0,40}\b(e-?mail|email)\b", t)
        or re.search(r"\b(your|company|contact)\s+(e-?mail|email)\b", t)
        or (
            re.search(r"\b(e-?mail|email)\s+address\b", t)
            and re.search(r"\b(ahmad|astechware|founder)\b", t)
        )
    )

    phone_hit = bool(
        re.search(r"\bcontact\s+number\b", t)
        or (
            re.search(r"\b(phone|mobile|whatsapp|telephone)\b", t)
            and re.search(r"\b(ahmad|astechware|founder|your|you|company|contact)\b", t)
        )
        or (
            re.search(r"\b(number)\b", t)
            and re.search(r"\b(phone|call|reach|contact)\b", t)
            and re.search(r"\b(ahmad|astechware|your|you|company)\b", t)
        )
    )

    general_contact = bool(
        re.search(
            r"\b(how\s+to\s+contact|contact\s+(info|information|details)|reach\s+(ahmad|you)|get\s+in\s+touch)\b",
            t,
        )
    )

    if email_hit and phone_hit:
        return "both"
    if email_hit:
        return "email"
    if phone_hit:
        return "phone"
    if general_contact:
        return "both"
    return None


def handle_contact_info_route(kind: str) -> dict:
    """Direct answer for public email/phone + meeting CTA (no RAG)."""
    meeting = {
        "type": "meeting",
        "label": "Book a 30-Min Technical Call",
        "taxonomy_key": None,
    }
    q_next = {
        "type": "question",
        "label": "What services does A'sTechware offer?",
        "taxonomy_key": None,
    }

    if kind == "email":
        body = (
            f"You can reach Ahmad at **{PUBLIC_CONTACT_EMAIL}**.\n\n"
            "For a focused conversation about your project, the best next step is usually a short technical "
            "call — use **Book a 30-Min Technical Call** below when you’re ready."
        )
    elif kind == "phone":
        body = (
            f"For phone inquiries, you can reach us at **{PUBLIC_CONTACT_PHONE_DISPLAY}** "
            f"(or **{PUBLIC_CONTACT_PHONE_RAW}**).\n\n"
            "We still recommend booking a **30-minute technical call** so we can understand scope and fit — "
            "use the button below."
        )
    else:
        body = (
            f"**Email:** {PUBLIC_CONTACT_EMAIL}  \n"
            f"**Phone:** {PUBLIC_CONTACT_PHONE_DISPLAY} ({PUBLIC_CONTACT_PHONE_RAW})\n\n"
            "For scoping or a tailored conversation, booking a short technical call is the fastest path."
        )

    return {
        "answer_markdown": body,
        "answer_style": "direct",
        "citations": [],
        "suggestions": [meeting, q_next],
        "confidence": 0.99,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {"contact_details_shared": True},
    }


def handle_in_scope_weak_evidence(question: str, classification: dict = None) -> dict:
    classification = classification or {}
    topics = classification.get("topics", []) or []

    related_note = ""
    if topics:
        pretty = ", ".join([pretty_topic_label(t) for t in topics[:3] if t])
        if pretty:
            related_note = f" The closest public fit appears to be around {pretty}."

    return {
        "answer_markdown": (
            "That exact use case isn’t clearly shown as a named public offering or public case study on A'sTechware today, "
            "so I wouldn’t overstate direct proof from the available material."
            f"{related_note} "
            "What is visible publicly is enough to suggest an adjacent fit through A'sTechware’s core strengths "
            "(AI agents/automation, custom platforms, platform modernization, or integrations), "
            "depending on the workflow. If helpful, I can map this to the closest service area and outline a likely approach."
            ),
        "answer_style": "low_confidence",
        "citations": [],
        "suggestions": [
            {
                "type": "question",
                "label": "What’s the closest A'sTechware case study to this?",
                "taxonomy_key": None
            },
            {
                "type": "question",
                "label": "Which A'sTechware service is the best fit here?",
                "taxonomy_key": None
            },
            {
                "type": "meeting",
                "label": "Book a 30-Min Technical Call",
                "taxonomy_key": None
            }
        ],
        "confidence": 0.45,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {
            "weak_public_evidence": True
        }
    }

# ═══════════════════════════════════════════════════════════════
# WEB ROUTE HELPERS (LIVE FETCH + SUMMARY)
# ═══════════════════════════════════════════════════════════════

URL_REGEX = re.compile(r'https?://[^\s)>\]]+')

# Web search controls (no Python scraping/fetching; model uses web search tool)
MAX_WEB_TEXT_CHARS = 18_000
MAX_WEB_SOURCES = 5


def extract_urls(text: str) -> List[str]:
    return URL_REGEX.findall(text or "")


def _safe_trim_text(s: str, limit: int) -> str:
    s = (s or "").strip()
    return s[:limit]


def _trim_at_word_boundary(s: str, limit: int) -> str:
    """Trim to at most `limit` chars at a word boundary (no mid-word cuts, no …)."""
    s = re.sub(r"\s+", " ", (s or "").strip())
    if len(s) <= limit:
        return s
    cut = s[:limit]
    last_space = cut.rfind(" ")
    if last_space >= max(24, limit // 5):
        return cut[:last_space].rstrip(".,;:")
    return cut.rstrip(".,;:")


def fetch_external_website_context(urls: List[str], user_input: str = "") -> dict:
    """
    Web-search powered context. No Python fetching/scraping.
    The model is expected to use web search to gather relevant info.
    """
    urls = [u.strip() for u in (urls or []) if u and u.strip()]
    urls = list(dict.fromkeys(urls))

    query = user_input.strip()
    if not query:
        query = " ".join(urls).strip()

    prompt = f"""
Use web search to gather a brief, reliable snapshot needed to answer the user.

Return ONLY valid JSON:
{{
  "fetched": true,
  "sources": [{{"title":"", "url":"", "snippet":""}}],
  "raw_text": "a compact synthesis of what you found (no long quotes, no raw HTML)"
}}

Guidelines:
- Prefer official pages/docs/pricing/about/security pages.
- Include up to {MAX_WEB_SOURCES} sources.
- Keep raw_text under {MAX_WEB_TEXT_CHARS} characters.
- If you cannot use web search, return fetched=false and explain why in raw_text.

User request:
{user_input}

URLs (if any):
{json.dumps(urls, ensure_ascii=False)}
""".strip()

    # Try OpenAI Responses API web search tool (if available in this environment/account).
    try:
        resp = openai_client.responses.create(
            model="gpt-5-mini",
            input=prompt,
            tools=[{"type": "web_search"}],
        )
        # Best-effort: extract the final JSON text from the response.
        text = ""
        for item in getattr(resp, "output", []) or []:
            content = getattr(item, "content", None)
            if not content:
                continue
            for c in content:
                if getattr(c, "type", None) in ("output_text", "text"):
                    text += getattr(c, "text", "") or ""
        data = json.loads(text.strip() or "{}")
        data["raw_text"] = _safe_trim_text(data.get("raw_text", ""), MAX_WEB_TEXT_CHARS)
        data["sources"] = (data.get("sources") or [])[:MAX_WEB_SOURCES]
        return data
    except Exception as e:
        return {
            "fetched": False,
            "sources": [],
            "raw_text": f"Web search is not available in this runtime/account configuration: {e}",
        }


def summarize_external_website(user_input: str, web_context: dict) -> dict:
    """
    Summarize external website/company/product context.

    Supports:
    - Web-search mode: web_context contains {"raw_text": "...", "sources":[...], "fetched": bool}
    - (Legacy) crawl mode: web_context contains {"pages":[{"url","text",...}], "fetched": bool}
    """
    web_context = web_context or {}
    fetched_flag = bool(web_context.get("fetched", False))

    joined = ""
    if (web_context.get("raw_text") or "").strip():
        joined = web_context.get("raw_text", "")
    else:
        pages = web_context.get("pages", []) or []
        joined = "\n\n".join(
            [
                f"[URL] {p.get('url','')}\n[TEXT]\n{p.get('text','')}"
                for p in pages
                if (p.get("text") or "").strip()
            ]
        )

    joined = _safe_trim_text(joined, MAX_WEB_TEXT_CHARS)

    # If fetch failed, return a safe stub for downstream flow.
    if not joined:
        return {
            "summary": "I couldn't fetch enough readable text from the provided link(s).",
            "product_type": "",
            "likely_industry": "",
            "core_features": [],
            "derived_rag_query": user_input,
            "fetched": False,
        }

    prompt = f"""
You are helping A'sTechware's assistant briefly understand an external site for lead qualification — not a long write-up.

Return ONLY valid JSON:
{{
  "summary": "1-2 short lines: what the product/site does (plain text, no URLs)",
  "product_type": "short label",
  "likely_industry": "one short label",
  "core_features": ["at most 2 short items"],
  "tech_hints": ["at most 2 short hints if visible"],
  "derived_rag_query": "one concise KB query for similar A'sTechware work"
}}

Rules:
- Minimal text. No mini consulting report.
- No raw URLs in values.

User request:
{user_input}

Extracted website text:
{joined}
""".strip()

    try:
        resp = openai_client.chat.completions.create(
            model=CHAT_BOT_OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
        )
        data = json.loads(resp.choices[0].message.content)
        data["fetched"] = True if joined else fetched_flag
        return data
    except Exception as e:
        return {
            "summary": "I fetched the site text, but summarization failed.",
            "product_type": "",
            "likely_industry": "",
            "core_features": [],
            "tech_hints": [],
            "derived_rag_query": user_input,
            "fetched": fetched_flag,
            "error": str(e),
        }


def build_ai_implementation_brief(user_input: str, website_summary: dict, web_context: dict) -> dict:
    """
    Turn the user's request + extracted site text into a concrete AI implementation brief.
    This brief is then used to generate a derived RAG query to find matching A'sTechware evidence.
    """
    web_context = web_context or {}
    joined = (web_context.get("raw_text") or "").strip()
    if not joined:
        pages = web_context.get("pages", []) or []
        joined = "\n\n".join(
            [
                f"[URL] {p.get('url','')}\n[TEXT]\n{p.get('text','')}"
                for p in pages
                if (p.get("text") or "").strip()
            ]
        )
    joined = _safe_trim_text(joined, MAX_WEB_TEXT_CHARS)

    site_summary = website_summary or {}
    prompt = f"""
You help A'sTechware qualify a lead from a website URL. Lead capture only — no roadmap, no phased rollout, no risk register.

Use only the provided website text/summary. If missing, say "unknown".

Return ONLY valid JSON with exactly these keys:
{{
  "ai_use_cases": ["2 or 3 short bullets max — how AI/product help could apply to THIS site"],
  "recommended_features": ["exactly 2 short bullets — concrete AI/product angles only"],
  "derived_rag_query": "one line to find similar A'sTechware evidence"
}}

User request:
{user_input}

Website summary (if available):
{json.dumps(site_summary, ensure_ascii=False)}

Extracted website text (may be partial):
{joined}
""".strip()

    try:
        resp = openai_client.chat.completions.create(
            model=CHAT_BOT_OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
        )
        raw = json.loads(resp.choices[0].message.content)
        return _normalize_implementation_brief(raw, user_input)
    except Exception as e:
        return {
            "ai_use_cases": [],
            "recommended_features": [],
            "derived_rag_query": user_input,
            "error": str(e),
        }


def _build_rag_plus_web_evidence_block(
    website_summary: dict,
    implementation_brief: dict,
    web_context: dict,
) -> str:
    """Prepends to RAG context so the model sees site + brief + web text alongside chunks."""
    ws = json.dumps(website_summary or {}, ensure_ascii=False)
    br = json.dumps(implementation_brief or {}, ensure_ascii=False)
    wt = (web_context or {}).get("raw_text") or ""
    if len(wt) > 8000:
        wt = _trim_at_word_boundary(wt, 8000)
    parts = [
        "=== INTERNAL WEB CONTEXT (do NOT use this text as a citation source_id; cite only chunk ids from the KNOWLEDGE BASE section below) ===",
        "The user shared a URL. Use this together with the knowledge-base chunks below.",
        f"Website summary (JSON): {ws}",
        f"Implementation brief from site (JSON): {br}",
    ]
    if wt.strip():
        parts.append(f"Extracted / synthesized web text (may be partial):\n{wt}")
    return "\n\n".join(parts)


def _normalize_implementation_brief(data: Any, fallback_query: str) -> dict:
    """Only ai_use_cases, recommended_features, derived_rag_query; cap list lengths."""
    if not isinstance(data, dict):
        data = {}
    uc = data.get("ai_use_cases") or []
    rf = data.get("recommended_features") or []
    if not isinstance(uc, list):
        uc = []
    if not isinstance(rf, list):
        rf = []
    drq = (data.get("derived_rag_query") or "").strip() or fallback_query
    return {
        "ai_use_cases": [str(x).strip() for x in uc[:3] if str(x).strip()],
        "recommended_features": [str(x).strip() for x in rf[:2] if str(x).strip()],
        "derived_rag_query": drq,
    }


def clean_answer_markdown_prose(text: str) -> str:
    """Strip internal chunk keys, raw URLs, and meeting links from answer body (CTAs live in suggestions)."""
    if not text:
        return ""
    s = text

    def _md_link_repl(m: re.Match) -> str:
        label, url = (m.group(1) or "").strip(), (m.group(2) or "").strip()
        if "calendly.com" in url.lower():
            return ""
        return label

    s = re.sub(r"\[([^\]]*)\]\((https?://[^)]+)\)", _md_link_repl, s)
    s = re.sub(r"https?://[^\s\)\]<>\"']+", "", s)
    # Internal RAG / page placeholder keys shown to the model in evidence
    s = re.sub(r"\[home-[^\]]+\]", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\[(?:chunk|source|page|section|nav)-[^\]]+\]", "", s, flags=re.IGNORECASE)
    # Kebab-slug placeholders like [foo-bar-baz] (chunk ids), not single words
    s = re.sub(r"\[[a-z0-9]+(?:-[a-z0-9]+){1,}\]", "", s, flags=re.IGNORECASE)
    s = re.sub(r"[ \t]{2,}", " ", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = re.sub(r"(\n|^)[ \t]*[\.,;:][ \t]*(\n|$)", "\n", s)
    return s.strip()


def generate_combined_answer_with_web_and_rag(
    user_input: str,
    router_result: dict,
    website_summary: dict,
    implementation_brief: dict,
    rag_result: dict,
) -> dict:
    """Post-process RAG+web result: answer text comes from generate_answer only (prompt-driven)."""
    out = dict(rag_result or {})
    out["answer_markdown"] = clean_answer_markdown_prose((out.get("answer_markdown") or "").strip())
    out["answer_style"] = "direct"

    sug = list(out.get("suggestions") or [])
    if not any((isinstance(s, dict) and s.get("type") == "meeting") for s in sug):
        sug.insert(
            0,
            {
                "type": "meeting",
                "label": "Book a 30-min discovery call",
                "taxonomy_key": None,
            },
        )
    out["suggestions"] = sug[:5]
    cf = out.get("commercial_flags") or {}
    if isinstance(cf, dict):
        cf["meeting_recommended"] = True
        cf["reason"] = "rag_plus_web_lead_focus"
        out["commercial_flags"] = cf

    return out


# ═══════════════════════════════════════════════════════════════
# STEP 1 — CLASSIFY THE QUESTION
# Supports mixed-scope queries like "cricket and HIPAA"
# ═══════════════════════════════════════════════════════════════

def classify_question(question: str) -> dict:
    prompt = f"""
You are a classifier for A'sTechware's website chatbot.

A'sTechware is an AI and product engineering company that builds:
- AI agents, copilots, and automation systems
- Custom SaaS platforms and internal tools
- Platform Modernization and Scaling — engineering rescues for failing platforms,
  incremental zero-downtime improvements, CI/CD, observability, database optimization,
  cloud cost reduction, and agency handoff rescues
- Integrations and API Engineering — connecting CRMs, billing, EHR, logistics dispatch,
  and payment systems with idempotency, dead letter queues, circuit breakers, webhook
  handling, HL7 FHIR, EDI X12, and SOAP/legacy adapters

They serve these industries:
- Healthcare and wellness (HIPAA, EHR, scheduling, telehealth)
- B2B SaaS (platform builds, AI features, MVP, scaling)
- Fintech (payments, compliance, banking, lending, earned wage access, fraud detection)
- Legal (contract review, document automation)
- Logistics, HVAC & Real Estate (field dispatch, route optimization, proof-of-service,
  property management, rent automation, showing platforms)
- Education technology (LMS, learning management, K-12, university, e-learning, corporate training, edtech)

They also have company pages covering:
- About, team, mission, values
- Methodology (6-step framework)
- Case studies and client results
- Contact and getting started

They also publish blog articles (URLs under /blogs/) covering these specific topics:
- Chatbot accuracy degradation and production monitoring (topics: chatbot, accuracy-drift, monitoring, feedback-loops, production-ai)
- AI cost control: model routing, semantic caching, token efficiency (topics: cost-optimization, model-routing, semantic-caching, token-efficiency)
- Prompt injection attacks and AI security controls (topics: prompt-injection, tool-safety, least-privilege, audit-trails)
- RAG pipeline mistakes: chunking, retrieval design, reranking, hallucinations (topics: rag, chunking, retrieval, reranking, hallucinations, metadata)
- Agentic AI governance: approval flows, staged autonomy, tool permissions (topics: agentic-ai, approval-flows, staged-autonomy, tool-permissions, automation-risk)
- Fine-tuning vs prompt engineering decisions (topics: fine-tuning, prompt-engineering, model-strategy, latency)
- How to evaluate an AI agent development company (topics: vendor-evaluation, governance, production-ai, ownership)
- Building production AI agents with LangGraph: state graphs, checkpointing, retries (topics: langgraph, agent-orchestration, state-management, checkpointing, fallbacks, auditability)
- HIPAA-compliant AI for healthcare: PHI handling, RAG risks, role-based access (topics: hipaa, healthcare-ai, minimum-necessary, rag, role-based-access, patient-scoped-retrieval)
- Large context windows and the lost-in-the-middle problem (topics: context-window, lost-in-the-middle, reranking, retrieval-ordering)
- Testing AI systems: non-determinism, adversarial testing, evals (topics: ai-testing, non-determinism, adversarial-testing, evals)
- Production AI vs prototype AI failure patterns (topics: production-ai, prototype-vs-production, observability, human-in-the-loop, governance)
- Hiring a fractional engineering team: ownership, handoff, execution capacity (topics: fractional-engineering, vendor-evaluation, ownership, handoff, execution-capacity)
- Reducing customer support tickets with AI agents (topics: customer-support-automation, ticket-deflection, human-handoff, ai-agents, operations-metrics)

Your job:
- Detect what A'sTechware service or industry this question relates to
- If the question mixes relevant content with unrelated content,
  mark it as partially in scope
- Keep only the relevant topics in "topics"
- Put obvious unrelated terms in "out_of_scope_terms"

MULTI-TURN TRANSCRIPTS (critical):
- The Question field may begin with "Conversation so far:" and lines like "user: ..." / "assistant: ..." (recent turns),
  then "User question:" and the *latest* user message only.
- Use the full transcript to interpret follow-ups, typos, and corrections. Example: after a healthcare discussion,
  "let's talk about fintech" or "no fintech" (correcting "funtech") means the user wants **fintech** — not contact info,
  not a random fragment in isolation.
- The "reformulated" field must be one **standalone retrieval query** that encodes the user’s *current* intent **in context**
  (industry, problem, capabilities). Do not set reformulated to a vague two-word fragment alone when the transcript
  defines the real topic (e.g. reformulate toward "A'sTechware fintech payments compliance AI financial services" when they pivot to fintech).

"evaluate" intent = user wants proof, evidence, results, examples, case studies, or how something was solved
"learn" intent = user wants to understand a concept, capability, or delivery approach
"trust_risk" intent = user is evaluating safety, credibility, ownership, responsibility, support, governance, lock-in, handoff, failure modes, or production risk
"challenge_fit" intent = user is describing a real business or technical problem and wants to know whether A'sTechware is a fit

Analyze this question and return JSON only, no explanation.

Question: "{question}"

Return exactly this structure:
{{
  "primary_category": one of {ALL_CATEGORIES},
  "topics": pick relevant from this list ONLY: {MASTER_TOPICS},
  "intent": one of ["learn", "evaluate", "compare", "trust_risk", "specific_feature", "challenge_fit"],
  "is_negative": true only if the user is explicitly skeptical, dissatisfied, or challenging A'sTechware's credibility, competence, or fit. Normal buyer caution, due diligence, pricing questions, or trust questions should not be marked negative unless the tone is clearly adversarial.
  "is_out_of_scope": true ONLY if the question is clearly unrelated to A'sTechware, software/product engineering, AI systems, technical delivery, supported industries, company credibility, buyer due diligence, or adjacent educational topics covered in A'sTechware content,
  "partially_in_scope": true if the question mixes relevant and unrelated topics,
  "out_of_scope_terms": ["list obvious unrelated terms"],
  "reformulated": a strong standalone retrieval query that preserves the user's real intent, strips filler words, and includes the most important capability, trust concern, industry, or problem. For trust or buyer-risk questions, explicitly include the A'sTechware process or safeguard being asked about (for example: ownership, lock-in, hallucination prevention, human approval, monitoring, handoff, support after launch).
}}

Category guidance:
- Use primary_category = "blog" when the user explicitly asks about a blog/article/post, asks "do you have an article about X", mentions an A'sTechware blog URL (astechware.com/blogs/...), or asks about a topic where a blog is the most direct answer (e.g. "how do chatbots degrade in production", "what are RAG implementation mistakes", "how should I evaluate an AI company").
- Use primary_category = "challenge" when the user is describing a problem they face and wants to know if A'sTechware can solve it.
- Use primary_category = "case_study" when they ask for client results, proof, or a specific case study.
- Casual or skeptical company-credibility questions such as "Who started this company?", "I've never heard of A'sTechware — are you a big company?", "Are you legit?", or "Are you just freelancers?" should use primary_category = "company", intent = "trust_risk" or "evaluate" depending on whether the user is asking for credibility or proof.
- Use primary_category = "service_capability" for what we build / how we deliver.
- Use primary_category = "challenge" when the user describes a real business or technical problem they are facing and wants to know if A'sTechware can solve it, improve it, stabilize it, modernize it, add AI to it, or integrate with an existing system. Examples: "our chatbot keeps making things up", "we already have a team, can you add AI?", "our support volume is too high", "our platform is slow and fragile", "can you fix this without rebuilding everything?"
- Subjective proof-of-work questions are still case-study questions. Examples like "What's the best thing you've ever built?", "What are you best at?", "What's your strongest result?", "What project are you most proud of?", "Show me something impressive", or "What has actually worked for clients?" should use primary_category = "case_study", intent = "evaluate", and is_out_of_scope = false.
- When in doubt between "blog" and "challenge": if the user is asking a general educational question about an AI concept, production failure pattern, or implementation best practice, prefer "blog". But if the question is about how A'sTechware handles that issue in real client work (for example: "How do you stop hallucinations?", "How do you prevent bad AI decisions?", "How do you handle production risk?"), prefer "company", "challenge", or "service_capability" instead of "blog".
- Use primary_category = "company" for questions about delivery model, engagement structure, ownership, milestones, transparency, de-risking, agency risk, no lock-in, handoff, stopping midway, support after launch, monitoring responsibility, escalation paths, AI safety process, governance, or how projects are run in production.
- If the user expresses trust concerns like "we've been burned by agencies", "how do you reduce risk", "what happens if we stop midway", "who owns the code", or "are we locked in", prefer "company" over "service_capability".
- For trust or risk questions, the reformulated query should be concrete and retrieval-friendly. Example: "Who is responsible if AI is wrong?" should reformulate toward terms like A'sTechware AI governance, human approval, escalation, audit trails, dangerous decisions, or production safeguards rather than staying as a vague conversational sentence.
- If the user asks about responsibility, hallucinations, dangerous AI behavior, failure handling, support after launch, monitoring, escalation, human approval, or whether the system is safe in production, use primary_category = "company" and intent = "trust_risk" unless they are explicitly asking for a specific feature implementation.
"""

    try:
        t_ai = time.perf_counter()
        response = openai_client.chat.completions.create(
            model=CHAT_BOT_OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"}
        )
        log_timing(
            "openai_chat",
            detail="classify_question model=gpt-4.1-nano",
            step_ms=(time.perf_counter() - t_ai) * 1000.0,
        )
        parsed = json.loads(response.choices[0].message.content)

        topics = normalize_topics(parsed.get("topics", []))

        # Safety: if we found topics, do NOT mark full out-of-scope
        is_out_of_scope = parsed.get("is_out_of_scope", False)
        if topics:
            is_out_of_scope = False
        # Safety: company/proof questions can be in-scope even with no topics match
        ql = (question or "").lower()
        proof_markers = [
            "best thing", "ever built", "best project", "biggest win",
            "most impressive", "case study", "case studies", "proof", "results",
            "what have you built", "what have you done", "portfolio",
            "google ads", "facebook ads", "meta ads", "ad campaign",
            "marketing automation", "social media",
        ]
        company_markers = [
            "who started", "founder", "founded", "who runs", "team",
            "company size", "how big", "where are you based", "about astechware",
        ]
        if any(m in ql for m in proof_markers + company_markers):
            is_out_of_scope = False


        # Safety: blog/educational AI questions and niche domain workflows are still in-scope
        in_scope_markers = [
            # blog / educational AI
            "prompt injection", "hallucination", "hallucinations", "rag", "fine-tuning",
            "fine tuning", "context window", "lost in the middle", "ai cost", "llm cost",
            "token", "semantic caching", "model routing", "why chatbots", "chatbot degrade",
            "production ai", "agentic ai", "langgraph", "evals", "adversarial testing",

            # niche legal / fintech / field ops / healthcare
            "m&a", "due diligence", "ediscovery", "e-discovery", "attorney-client privilege",
            "pci", "pci dss", "earned wage access", "ewa", "salary advance",
            "hvac", "property maintenance", "field service", "proof of service",
            "42 cfr part 2", "substance use disorder", "sud",

            "google ads", "facebook ads", "meta ads", "ad campaign",
            "social media automation", "marketing automation", "eventvesta",
            "ad creative", "paid social", "meta graph api",
        ]

        if any(m in ql for m in in_scope_markers):
            is_out_of_scope = False

        return {
            "primary_category": parsed.get("primary_category", "unknown"),
            "topics": topics,
            "intent": parsed.get("intent", "learn"),
            "is_negative": parsed.get("is_negative", False),
            "is_out_of_scope": is_out_of_scope,
            "partially_in_scope": parsed.get("partially_in_scope", False),
            "out_of_scope_terms": parsed.get("out_of_scope_terms", []),
            "reformulated": parsed.get("reformulated", question),
        }
    except Exception as e:
        print(f"  → Classification failed, using fallback classification: {e}")
        return {
            "primary_category": "unknown",
            "topics": [],
            "intent": "learn",
            "is_negative": False,
            "is_out_of_scope": False,
            "partially_in_scope": False,
            "out_of_scope_terms": [],
            "reformulated": question,
        }


# ═══════════════════════════════════════════════════════════════
# STEP 2 — BUILD SMART FILTERS
# ═══════════════════════════════════════════════════════════════

def is_proof_query(question: str) -> bool:
    q = question.lower()
    proof_phrases = [
        "example", "examples", "case study", "case studies", "proof",
        "have you done", "have you built", "have you worked on",
        "similar project", "portfolio", "results", "show me examples",
        "show me case studies", "real project", "real-world",
        "experience with", "do you have experience", "have experience with",
        "have you integrated", "have you handled", "worked with"
    ]
    return any(p in q for p in proof_phrases)



# Blog topic slugs — must match the exact topic values used in blog chunk metadata
BLOG_TOPICS = {
    "production-ai", "chatbot", "monitoring", "feedback-loops", "accuracy-drift",
    "prompt-iteration", "human-in-the-loop", "cost-optimization", "model-routing",
    "semantic-caching", "token-efficiency", "vendor-evaluation", "prompt-injection",
    "tool-safety", "least-privilege", "audit-trails", "rag", "chunking", "retrieval",
    "reranking", "hallucinations", "metadata", "fallbacks", "retrieval-design",
    "agentic-ai", "approval-flows", "automation-risk", "staged-autonomy",
    "tool-permissions", "fine-tuning", "prompt-engineering", "latency",
    "model-strategy", "ownership", "langgraph", "agent-orchestration",
    "state-management", "checkpointing", "retries", "auditability", "healthcare-ai",
    "minimum-necessary", "role-based-access", "patient-scoped-retrieval",
    "context-window", "lost-in-the-middle", "retrieval-ordering", "ai-testing",
    "non-determinism", "adversarial-testing", "evals", "prototype-vs-production",
    "fractional-engineering", "handoff", "execution-capacity",
    "customer-support-automation", "ticket-deflection", "operations-metrics",
}


def is_blog_topic_question(topics: list) -> bool:
    """Returns True if any of the question's topics exist in blog chunk metadata."""
    return any(t in BLOG_TOPICS for t in (topics or []))


def build_filters(classification: dict) -> dict:
    """
    Build Supabase filter dict from classification.

    Multi-category strategy — answers your question about blog+challenge overlap:
    We never restrict to a single category. Instead we build a category list and
    let hybrid search + re-ranking pick the best chunks across all relevant buckets.

    Rules applied in order:
    1. Start from primary_category's base list.
    2. If any topic is a blog topic → always add "blog" to the list.
    3. If primary_category is "blog" → also add "service_capability" so service
       chunks supplement blog chunks for context.
    4. If intent is evaluate or it is a proof query → add service_capability +
       case_study (existing behaviour, unchanged).
    """
    proof_query = is_proof_query(classification.get("reformulated", ""))
    cat     = classification.get("primary_category", "unknown")
    intent  = classification.get("intent", "learn")
    topics  = normalize_topics(classification.get("topics", []))

    category_map = {
        "challenge":          ["challenge"],
        "service_capability": ["service_capability"],
        "compliance":         ["compliance", "service_capability"],
        "case_study":         ["case_study"],
        "blog":               ["blog"],
        "faq":                ["faq", "service_capability"],
        "company":            ["company"],
        "general":            None,
        "unknown":            None,
    }

    base = list(category_map.get(cat) or [])

    # Rule 2: blog topics detected → always include the blog bucket
    if is_blog_topic_question(topics) and "blog" not in base:
        base.append("blog")

    # Rule 3: blog-primary questions benefit from service context too
    if cat == "blog" and "service_capability" not in base:
        base.append("service_capability")

    # Rule 4: evaluate / proof → pull service + case study
    if intent == "evaluate" or proof_query:
        for extra in ["service_capability", "case_study"]:
            if extra not in base:
                base.append(extra)

    filters: dict = {}
    if base:
        filters["categories"] = list(dict.fromkeys(base))  # dedupe, preserve order

    if topics:
        filters["topics"] = topics

    return filters




# ═══════════════════════════════════════════════════════════════
# STEP 3 — EMBED THE QUESTION
# ═══════════════════════════════════════════════════════════════

def embed_text(text: str) -> list:
    try:
        t_ai = time.perf_counter()
        response = openai_client.embeddings.create(
            model="text-embedding-3-small",
            input=text.replace("\n", " ").strip()
        )
        log_timing(
            "openai_embeddings",
            detail="model=text-embedding-3-small",
            step_ms=(time.perf_counter() - t_ai) * 1000.0,
        )
        return response.data[0].embedding
    except Exception as e:
        raise RuntimeError(f"Embedding failed: {e}")


# ═══════════════════════════════════════════════════════════════
# STEP 4 — HYBRID SEARCH (VECTOR + FTS/BM25-ish)
# Requires Supabase RPC functions:
#   - match_chunks_vector
#   - match_chunks_fts
# ═══════════════════════════════════════════════════════════════

def search_supabase_vector(question_embedding: list, filters: dict) -> list:
    def run_search(cats=None, topics=None):
        params = {
            "query_embedding": question_embedding,
            "match_threshold": LOW_CONFIDENCE,
            "match_count": SEARCH_K,
            "filter_industry": None,
            "filter_source_url": None,
        }

        if cats:
            params["filter_categories"] = cats

        if topics:
            params["filter_topics"] = normalize_topics(topics)

        result = supabase_client.rpc("match_chunks_vector", params).execute()
        rows = result.data or []

        for row in rows:
            row["retrieval_source"] = "vector"
            row["vector_score"] = row.get("similarity", 0.0)

        return rows

    categories = filters.get("categories")
    topics = filters.get("topics")

    try:
        t_rpc = time.perf_counter()
        results = run_search(cats=categories, topics=topics)

        if not results and topics:
            print("  → vector topic-filtered search empty, retrying without topic filter")
            results = run_search(cats=categories, topics=None)

        if not results and categories:
            print("  → vector category-filtered search empty, retrying full scoped search")
            results = run_search(cats=None, topics=None)

        log_timing(
            "supabase_rpc_match_chunks_vector",
            detail=f"rows={len(results)}",
            step_ms=(time.perf_counter() - t_rpc) * 1000.0,
        )
        return results
    except Exception as e:
        print(f"  → Vector search failed: {e}")
        return []


def search_supabase_fts(query_text: str, filters: dict) -> list:
    def run_search(cats=None, topics=None):
        params = {
            "query_text": query_text,
            "match_count": SEARCH_K,
            "filter_industry": None,
            "filter_source_url": None,
        }

        if cats:
            params["filter_categories"] = cats

        if topics:
            params["filter_topics"] = normalize_topics(topics)

        result = supabase_client.rpc("match_chunks_fts", params).execute()
        rows = result.data or []

        for row in rows:
            row["retrieval_source"] = "fts"
            row["lexical_score"] = row.get("lexical_score", 0.0)

        return rows

    categories = filters.get("categories")
    topics = filters.get("topics")

    try:
        t_rpc = time.perf_counter()
        results = run_search(cats=categories, topics=topics)

        if not results and topics:
            print("  → FTS topic-filtered search empty, retrying without topic filter")
            results = run_search(cats=categories, topics=None)

        if not results and categories:
            print("  → FTS category-filtered search empty, retrying full scoped search")
            results = run_search(cats=None, topics=None)

        log_timing(
            "supabase_rpc_match_chunks_fts",
            detail=f"rows={len(results)}",
            step_ms=(time.perf_counter() - t_rpc) * 1000.0,
        )
        return results
    except Exception as e:
        print(f"  → FTS search failed: {e}")
        return []


def reciprocal_rank_fusion(vector_results, fts_results, k=60):
    merged = {}

    def add_results(results, source_name):
        for rank, row in enumerate(results, start=1):
            chunk_id = row.get("chunk_id")
            if not chunk_id:
                continue
            if chunk_id not in merged:
                merged[chunk_id] = dict(row)
                merged[chunk_id]["rrf_score"] = 0.0
                merged[chunk_id]["sources"] = set()
            merged[chunk_id]["rrf_score"] += 1.0 / (k + rank)
            merged[chunk_id]["sources"].add(source_name)
            if "similarity" in row:
                merged[chunk_id]["similarity"] = max(
                    merged[chunk_id].get("similarity", 0.0),
                    row["similarity"]
                )
            if "lexical_score" in row:
                merged[chunk_id]["lexical_score"] = max(
                    merged[chunk_id].get("lexical_score", 0.0),
                    row["lexical_score"]
                )

    add_results(vector_results, "vector")
    add_results(fts_results, "fts")

    fused = list(merged.values())

    # Normalize RRF scores to 0-1 range
    max_rrf = max((r.get("rrf_score", 0) for r in fused), default=1)
    min_rrf = min((r.get("rrf_score", 0) for r in fused), default=0)
    rrf_range = max_rrf - min_rrf or 1

    for row in fused:
        rrf_norm = (row.get("rrf_score", 0) - min_rrf) / rrf_range
        sim = row.get("similarity", 0.0)
        lex = min(row.get("lexical_score", 0.0), 0.5)

        # Blend: 50% rank position + 30% semantic score + 20% lexical score
        row["final_score"] = (0.5 * rrf_norm) + (0.3 * sim) + (0.2 * lex)
        row["sources"] = sorted(list(row["sources"]))

    return sorted(fused, key=lambda x: x.get("final_score", 0.0), reverse=True)


def clean_for_fts(text: str) -> str:
    """Strip filler words, keep only meaningful keywords for FTS"""
    stop_words = {
        'let', 'me', 'know', 'about', 'tell', 'what', 'is', 'are',
        'how', 'does', 'do', 'the', 'a', 'an', 'and', 'or', 'for',
        'to', 'of', 'in', 'on', 'at', 'with', 'we', 'our', 'your',
        'you', 'i', 'my', 'can', 'could', 'would', 'should', 'have',
        'has', 'had', 'been', 'be', 'will', 'just', 'also', 'than'
    }
    words = text.lower().split()
    keywords = [w.strip('.,?!') for w in words if w.strip('.,?!') not in stop_words]
    return ' | '.join(keywords) if keywords else text


def search_hybrid(question_text: str, question_embedding: list, filters: dict) -> list:
    vector_results = search_supabase_vector(question_embedding, filters)
    fts_query = clean_for_fts(question_text)
    fts_results = search_supabase_fts(fts_query, filters)

    if not vector_results and not fts_results:
        return []

    if not vector_results:
        print("  → vector empty, using FTS only")
        for i, row in enumerate(fts_results, start=1):
            row["rrf_score"] = 1.0 / (60 + i)
            row["sources"] = ["fts"]
        return fts_results

    if not fts_results:
        print("  → FTS empty, using vector only")
        for i, row in enumerate(vector_results, start=1):
            row["rrf_score"] = 1.0 / (60 + i)
            row["sources"] = ["vector"]
        return vector_results

    return reciprocal_rank_fusion(vector_results, fts_results)


# ═══════════════════════════════════════════════════════════════
# STEP 5 — RE-RANK RESULTS
# Uses hybrid fused score (RRF) as base
# ═══════════════════════════════════════════════════════════════

PRIMARY_SERVICE_TOPICS = {
    "ai-agents",
    "automation",
    "custom-software",
    "saas-platform",
    "platform-modernization",
    "api-integrations",
}

BRIDGE_CHUNK_IDS = {
    "casestudies-customsoftware-bridge",
    "casestudies-apiintegrations-bridge",
    "casestudies-platformmodernization-bridge",
}


def rerank_results(results: list, classification: dict) -> list:
    question_topics = set(normalize_topics(classification.get("topics", [])))
    intent = classification.get("intent", "learn")

    for chunk in results:
        metadata = chunk.get("metadata", {}) or {}
        chunk_topics = set(normalize_topics(metadata.get("topics", [])))
        overlap = len(question_topics & chunk_topics)

        chunk_category = chunk.get("category") or metadata.get("category", "unknown")
        chunk["category"] = chunk_category

        # Base score from hybrid fusion (small by nature)
        score = chunk.get("final_score", chunk.get("rrf_score", 0.0))

        chunk_id = chunk.get("chunk_id", "")
        is_bridge_chunk = chunk_id in BRIDGE_CHUNK_IDS

        # Bridge boost for service-level proof queries
        if is_bridge_chunk and intent in ["evaluate", "compare"]:
            if "custom-software" in question_topics and chunk_id == "casestudies-customsoftware-bridge":
                score += 0.10
            if "api-integrations" in question_topics and chunk_id == "casestudies-apiintegrations-bridge":
                score += 0.10
            if "platform-modernization" in question_topics and chunk_id == "casestudies-platformmodernization-bridge":
                score += 0.10

        # Boost if found by both vector + FTS
        sources = set(chunk.get("sources", []))
        if "vector" in sources and "fts" in sources:
            score += 0.03

        # Topic overlap
        if overlap > 0:
            score += 0.04 * overlap

        primary_overlap = len(question_topics & chunk_topics & PRIMARY_SERVICE_TOPICS)
        if primary_overlap > 0:
            score += 0.06 * primary_overlap

        # Intent/category boosts
        if intent == "evaluate" and chunk_category == "case_study":
            score += 0.08

        if intent == "learn" and chunk_category == "faq":
            score += 0.03

        # ── Blog chunk boost ──────────────────────────────────────
        # When the question contains blog topics, boost blog chunks that
        # share those topics. Without this, service_capability chunks
        # (which have broader topic overlap) would always outscore blog chunks.
        blog_question_topics = question_topics & BLOG_TOPICS
        if blog_question_topics and chunk_category == "blog":
            blog_chunk_topics = chunk_topics & BLOG_TOPICS
            direct_blog_overlap = len(blog_question_topics & blog_chunk_topics)
            # Strong boost for direct topic match, smaller boost for any blog chunk
            score += 0.12 if direct_blog_overlap > 0 else 0.05

        # When primary_category is blog, lightly penalise low-signal categories
        # (faq, company) so they don't crowd out blog + service chunks
        primary_cat = classification.get("primary_category", "")
        if primary_cat == "blog" and chunk_category in ("faq", "company"):
            score -= 0.04

        # Trust boost
        if metadata.get("knowledge_type") == "verified":
            score += 0.01

        chunk["final_score"] = score

    return sorted(results, key=lambda x: x.get("final_score", 0), reverse=True)


# ═══════════════════════════════════════════════════════════════
# STEP 6 — FETCH RELATED CHUNKS + BUILD CONTEXT
# ═══════════════════════════════════════════════════════════════

def fetch_related_chunks(top_results: list) -> list:
    if not top_results:
        return []

    top_chunk = top_results[0]
    top_chunk_id = top_chunk.get("chunk_id", "")
    max_related = 4 if top_chunk_id in BRIDGE_CHUNK_IDS else 2
    related_ids = top_chunk.get("metadata", {}).get("related_chunks", [])[:max_related]
    fetched = []

    for rel_chunk_id in related_ids:
        already_in = any(r.get("chunk_id") == rel_chunk_id for r in top_results)
        if already_in:
            continue

        try:
            res = (
                supabase_client.table("chunks")
                .select("chunk_id, category, content, metadata")
                .eq("chunk_id", rel_chunk_id)
                .execute()
            )

            if res.data:
                chunk = res.data[0]
                chunk["final_score"] = 0.5
                chunk["is_related"] = True
                fetched.append(chunk)
        except Exception as e:
            print(f"  → Failed fetching related chunk {rel_chunk_id}: {e}")

    return fetched


def select_balanced_top_chunks(results: list, top_k: int = TOP_K, classification: dict = None) -> list:
    """
    Balance chunks across categories so no single category starves another.

    - Blog questions  → 2 blog + 1 service + 1 case + 1 other
    - Evaluate/proof  → 2 service + 2 case + 1 other  (existing behaviour)
    - Default         → score-ordered top_k

    Blog chunks would otherwise lose to service_capability chunks in the
    default top_k slice because service chunks have broader topic overlap.
    """
    if not results:
        return []

    classification = classification or {}
    primary_cat = classification.get("primary_category", "")
    topics = normalize_topics(classification.get("topics", []))
    is_blog_q = primary_cat == "blog" or is_blog_topic_question(topics)

    blog_chunks    = []
    service_chunks = []
    case_chunks    = []
    other_chunks   = []

    for chunk in results:
        cat = chunk.get("category") or (chunk.get("metadata", {}) or {}).get("category", "unknown")
        if cat == "blog":
            blog_chunks.append(chunk)
        elif cat == "service_capability":
            service_chunks.append(chunk)
        elif cat == "case_study":
            case_chunks.append(chunk)
        else:
            other_chunks.append(chunk)

    selected = []

    if is_blog_q:
        # Lead with blog chunks, supplement with service + case for context
        selected.extend(blog_chunks[:2])
        selected.extend(service_chunks[:1])
        selected.extend(case_chunks[:1])
    else:
        # Default: 2 service + 2 case
        selected.extend(service_chunks[:2])
        selected.extend(case_chunks[:2])

    # Fill remaining slots from the full ranked list (score-ordered)
    used_ids = {c.get("chunk_id") for c in selected}
    leftovers = [c for c in results if c.get("chunk_id") not in used_ids]
    selected.extend(leftovers[:max(0, top_k - len(selected))])

    return selected[:top_k]


def build_context(top_results: list, related: list, classification: dict) -> str:
    proof_query = (
        classification.get("intent") in ["evaluate", "compare"]
        or is_proof_query(classification.get("reformulated", ""))
    )
    topics = normalize_topics(classification.get("topics", []))
    is_blog_q = (
        classification.get("primary_category") == "blog"
        or is_blog_topic_question(topics)
    )

    if proof_query or is_blog_q:
        selected_top = select_balanced_top_chunks(top_results, TOP_K, classification=classification)
    else:
        selected_top = top_results[:TOP_K]

    all_chunks = selected_top + related
    parts = []

    for chunk in all_chunks:
        metadata = chunk.get("metadata", {}) or {}
        trust = metadata.get("knowledge_type", "verified")

        title = (
            metadata.get("source_page")
            or "Untitled"
        )

        url = (
            metadata.get("source_url")
            or ""
        )

        label = (
            f"[{chunk.get('chunk_id')} | trust:{trust} | "
            f"score:{chunk.get('final_score', 0):.2f} | "
            f"title:{title} | url:{url}]"
        )
        parts.append(f"{label}\n{chunk.get('content', '')}")

    return "\n\n---\n\n".join(parts)


# ═══════════════════════════════════════════════════════════════
# STEP 7 — GENERATE STRUCTURED ANSWER
# IMPORTANT:
# Let the LLM return ONLY source_id for citations.
# Python will enrich title/url after generation.
# ═══════════════════════════════════════════════════════════════

SYSTEM_PROMPT = """
You are A'sTechware's website AI assistant.

VOICE / POV (strict):
- Speak as A'sTechware using first-person plural: "we", "our", "us".
- Do NOT describe A'sTechware as a third party ("they", "their") unless you are quoting a user.
- When referring to capabilities, use phrasing like: "We build…", "We typically…", "Our team…".

PRIMARY GOAL:
- Help qualify and convert inbound leads.
- Show capability first.
- Keep answers concise by default.
- Use suggestions for the meeting CTA when the user appears to have project intent.
- Preserve the pipeline's existing source/citation behavior.

DEFAULT RESPONSE STYLE:
- Be short, skimmable, and point-to-point.
- Usually 2-5 short bullets or short paragraphs max.
- Do NOT go deep by default.
- Only go deeper if the user explicitly asks for details, architecture, step-by-step, deep dive, or technical explanation.
- Avoid long consulting-style answers unless explicitly requested.

MULTI-TURN CHAT:
- When the question includes "Conversation so far:" and "User question:", use prior turns so follow-ups, corrections,
  and topic switches (e.g. healthcare then fintech) are understood. Answer the latest user message in that context;
  do not treat a short follow-up as if it were the opening message.

COMMERCIAL BEHAVIOR:
- If the user asks whether A'sTechware can build, integrate, automate, modernize, migrate, or support something, optimize for confidence + capability + proof.
- If the user appears to have an active project or buying intent, the answer should naturally support a meeting suggestion in the suggestions list (not forced inside answer_markdown).
- If exact public proof is limited, mention the closest visible fit instead of over-explaining the limitation.

SPECIFIC SCENARIOS:
1) "What do you guys do?"
- Answer precisely with the industries and service lines A'sTechware works in.
- Keep it short.
- Let citations/sources provide proof and links.

2) HIPAA / FHIR / HL7 / compliance questions
- Start with a direct yes-style answer if supported by relevant evidence.
- Mention 1-2 relevant project or capability headings.
- Keep the total body brief (around 4-5 short lines or equivalent).
- Let citations/sources carry the case study proof.
- Do not turn it into a compliance essay.

3) Website / URL review (RAG + Web)
- Give only 1-2 concise observations from the website.
- Then state 1-2 likely A'sTechware fit points.
- Do NOT provide a full audit, roadmap, or free strategy doc by default.
- Deeper analysis should be left for follow-up / meeting suggestion flow.

4) General capability / fit questions
- Focus on what A'sTechware is capable of.
- Avoid unnecessary implementation detail.
- Be commercially useful, not academically exhaustive.

5) Contact: email, phone, WhatsApp, or how to reach Ahmad / A'sTechware
- Answer directly if the user asks for contact details: public email is ahmad@astechware.com; phone (888) 348-8752 (8883488752).
- Always recommend a short technical call as the best next step for project scoping; add a `meeting` suggestion (not a raw Calendly URL in markdown).
- This is in-scope — never answer with a generic “I can only help with services” deflection.

IMPORTANT:
- Keep the existing response schema intact.
- Keep sources/citations intact and do not suppress them.
- Do NOT force meeting language into answer_markdown unless it is already naturally appropriate.
- Prefer short, confident, useful answers that move the lead forward.
- In answer_markdown: never paste internal evidence keys like [home-about-summary], [home-company-overview], [home-services-overview], or any similar [bracket-label] placeholders; use citations for sources.
- Never put Calendly or other booking URLs in answer_markdown (no raw https links and no markdown links); use a meeting-type suggestion for booking instead.

CITATIONS (strict):
- Each citations[].source_id MUST be an exact chunk id from the evidence chunk labels (format `[chunk-id | trust:...]`). Never invent ids, never use section headers, preambles like "URL / WEBSITE", JSON keys, or free text as source_id.
- If nothing qualifies, use an empty citations array []. Never add citations with empty url or title "Untitled" (the server drops invalid entries).
"""


def has_case_study_in_top(results: list, n: int = 5) -> bool:
    for chunk in results[:n]:
        cat = chunk.get("category") or (chunk.get("metadata", {}) or {}).get("category", "unknown")
        if cat == "case_study":
            return True
    return False


def generate_answer(
    question: str,
    context: str,
    classification: dict,
    confidence_score: float,
    *,
    rag_plus_web_generation: bool = False,
) -> dict:
    if confidence_score >= HIGH_CONFIDENCE:
        confidence_note = "You have strong evidence. Answer confidently and cite sources."
    elif confidence_score >= MEDIUM_CONFIDENCE:
        confidence_note = "You have partial evidence. Give the strongest supported answer first, clearly separate supported facts from uncertainty, and avoid over-absolute or legal-sounding claims."
    else:
        confidence_note = "Evidence is weak. Give the best supported answer you can using any relevant evidence, be explicit about uncertainty, avoid hard claims, and only suggest a call if it is genuinely the most helpful next step."

    negative_note = ""
    if classification.get("is_negative"):
        negative_note = (
            "This is a challenging or skeptical buyer question. Acknowledge the concern calmly, "
            "answer it directly with evidence, avoid defensiveness, avoid over-claiming, and do not deflect."
        )

    if rag_plus_web_generation:
        structure_and_length = """
<url_review_mode>
The user shared a URL and wants fit / how A'sTechware could help. Evidence includes WEBSITE SUMMARY + IMPLEMENTATION BRIEF + KNOWLEDGE-BASE CHUNKS.
This mode overrides the generic 3–5 sentence / brevity_mode rules elsewhere in this prompt.

Write the full reply in answer_markdown yourself (no Python templating). Rules:
- Do NOT use # or ## markdown headings.
- Start with one natural sentence that you checked the site or URL they gave (or that the link did not yield much text).
- Briefly reflect what the site/product does in plain language (short).
- Merge "can we help" and concrete angles into one flowing section: confirm fit, then bullets or short sentences for how A'sTechware could help — not separate titled blocks like "Site snapshot" or "AI angles".
- Ground proof and credibility in the knowledge-base chunks; cite via citations only using source_id values copied from chunk labels `[chunk-id | ...]` in the KNOWLEDGE BASE part of evidence — never cite the INTERNAL WEB CONTEXT preamble.
- Do not paste internal bracket keys like [home-...] into the prose.
- End with a light next-step line if appropriate (no Calendly/markdown links in the body; use a meeting suggestion).
- Aim for roughly 6–14 short lines unless the user asked for depth.
</url_review_mode>
"""
    else:
        structure_and_length = """
<brevity_mode_instruction>
- Unless the user explicitly asks for deep explanation or how something works, keep answer_markdown to 3–5 concise lines. Use a heading + 1–2 project name mentions + 1 short paragraph. Always add a meeting CTA to suggestions if the question implies a potential project.
</brevity_mode_instruction>
"""

    user_prompt = f"""
<evidence>
{context}
</evidence>

<question>
{question}
</question>

<topline_behavior>
Answer the user's actual question directly using the strongest supported evidence. Prefer qualified, natural wording over absolute claims. Do not dodge valid in-scope questions.
</topline_behavior>

<multi_turn_conversation>
The <question> block may include "Conversation so far:" (recent user/assistant turns, typically up to 5 messages)
and then "User question:" with the newest user message. Use the prior turns to resolve typos, corrections ("no fintech"
after "funtech"), topic pivots, and pronouns. If the user switches industry or topic (e.g. from a clinic use case to
fintech), answer for the **new** topic using evidence; a one-line bridge from earlier context is optional if helpful.
</multi_turn_conversation>

<classification>
{json.dumps(classification, ensure_ascii=False)}
</classification>

<instructions>
{confidence_note}
{negative_note}
</instructions>

<answer_policy>
- Use the strongest supported answer, but avoid legal or absolute wording unless the evidence explicitly supports it.
- For responsibility, liability, ownership, or risk questions, prefer phrasing like: "A'sTechware reduces risk by...", "A'sTechware is designed to lower the chance of...", "For sensitive workflows, A'sTechware uses...", or "Exact responsibility depends on how the system is scoped..."
- Avoid phrasing like: "A'sTechware takes responsibility for all errors", "A'sTechware guarantees no failures", or any blanket ownership/liability statement unless explicitly supported by evidence.
- Keep the answer to 3–5 sentences. Depth is only unlocked when the user explicitly asks for details.
- Do not paste bracketed context keys (e.g. [home-...]) into answer_markdown. Do not add Calendly or any URL as a markdown link; add a `meeting` suggestion instead.
- Voice: write as A'sTechware ("we/our"), not "they/their".
</answer_policy>

<estimate_policy>
- For timelines, delivery ranges, and operating estimates, use evidence-backed ranges as typical patterns, not guarantees.
- Prefer phrasing like: "typically", "usually", "common range", "for many projects", or "for a typical engagement".
- If the evidence includes a specific range (for example 3-8 weeks), present it as a common or typical range, not as a guaranteed deadline.
- Never imply a hard commitment unless the evidence explicitly supports one.
</estimate_policy>

<subjective_question_policy>
- For broad, subjective, or judgment-based buyer questions, answer directly using the strongest evidence-backed framing rather than refusing because the question is broad.
- Prefer natural qualifiers like: "depends on the use case, but...", "one of the strongest examples is...", "typically...", or "if by best you mean measurable impact..."
- Do not force rigid canned phrasing; keep the answer natural, direct, and grounded in evidence.
</subjective_question_policy>

<suggestion_policy>
- Suggestions are optional and secondary. Only include suggestions if they naturally help the user continue.
- Do not use suggestions as a substitute for answering the question.
- Prefer zero or one highly relevant suggestion over multiple generic suggestions.
- For trust, founder, company credibility, or governance questions, avoid pushing a meeting CTA unless the user is explicitly asking for next steps or scoping.
- Always include a meeting suggestion whenever the user's question implies a business need, a specific project, a compliance question, or a technology fit question. Only skip the meeting CTA for pure educational/conceptual questions
</suggestion_policy>

{structure_and_length}

Choose answer_style like this:
- "direct" for clear evidence-backed answers, including trust/governance answers that can be answered with safeguards and operating model
- "advisory" when the answer requires some interpretation, tradeoff framing, or partial evidence
- "clarifying" only when the user question is too ambiguous to answer responsibly
- "low_confidence" only when there is truly insufficient evidence for a meaningful answer

Set needs_clarification=true only when a direct answer would be misleading because the user's request is too vague or missing essential scope. Do not ask for clarification if a useful evidence-backed answer can still be given.

Citations: each source_id must match a chunk id from the evidence (see `[chunk-id | trust:...]` lines). Never use labels like "URL / WEBSITE", section titles, or sentences. Use [] if none apply.

Return ONLY this JSON structure, nothing else:
{{
  "answer_markdown": "your answer in markdown",
  "answer_style": "direct|advisory|clarifying|low_confidence",
  "citations": [
    {{"source_id": "exact-id-from-evidence-chunk-label"}}
  ],
  "suggestions": [
    {{
      "type": "service|case_study|question|meeting",
      "label": "short human-readable button text e.g. 'View Fintech Case Studies'",
      "taxonomy_key": "ai_agents_automation"
    }}
  ],
  "confidence": 0.0,
  "needs_clarification": false,
  "clarifying_question": null,
  "commercial_flags": {{
    "mentions_budget": false,
    "mentions_timeline": false,
    "contains_final_quote": false,
    "contains_hard_promise": false
  }}
}}
"""

    try:
        t_ai = time.perf_counter()
        response = openai_client.chat.completions.create(
            model=CHAT_BOT_OPENAI_MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt}
            ],
            response_format={"type": "json_object"}
        )
        log_timing(
            "openai_chat",
            detail="generate_answer model=gpt-4.1-nano",
            step_ms=(time.perf_counter() - t_ai) * 1000.0,
        )
        data = json.loads(response.choices[0].message.content)
        if isinstance(data, dict) and "answer_markdown" in data:
            data["answer_markdown"] = clean_answer_markdown_prose(data.get("answer_markdown") or "")
        return data
    except Exception as e:
        print(f"  → Answer generation failed: {e}")
        return {
            "answer_markdown": "I found some relevant information, but I couldn't generate a reliable final answer right now.",
            "answer_style": "low_confidence",
            "citations": [],
            "suggestions": [],
            "confidence": 0.0,
            "needs_clarification": True,
            "clarifying_question": "Would you like me to narrow this down to implementation, compliance, or case studies?",
            "commercial_flags": {}
        }


# ═══════════════════════════════════════════════════════════════
# STEP 8 — ENRICH CITATIONS
# Resolve source_id → authoritative title/url from retrieved chunks
# ═══════════════════════════════════════════════════════════════

def clean_url(url: str) -> str:
    if not url:
        return ""
    # Extract URL from markdown link syntax [text](url)
    match = re.search(r'\(?(https?://[^\s)\]]+)\)?', url)
    if match:
        url = match.group(1)
    # Ensure protocol
    if not url.startswith("http"):
        url = "https://" + url.lstrip("/")
    return url.strip()


def _humanize_chunk_id_for_title(source_id: str) -> str:
    parts = [p for p in re.split(r"[-_\s]+", (source_id or "").strip()) if p]
    if not parts:
        return "Source"
    return " ".join(p.capitalize() for p in parts)


def _looks_like_non_chunk_source_id(source_id: str) -> bool:
    """True if model echoed evidence preamble / headers instead of a real chunk_id."""
    s = (source_id or "").strip()
    if not s or len(s) > 120:
        return True
    low = s.lower()
    needles = (
        "url / website",
        "url/website",
        "=== ",
        "for this turn",
        "internal_web",
        "internal web",
        "do not cite",
        "rag_plus_web",
        "website (json)",
        "implementation brief",
        "extracted / synthesized",
        "http://",
        "https://",
    )
    if any(n in low for n in needles):
        return True
    if s.startswith("[") or s.startswith("("):
        return True
    return False


def enrich_citations(answer: dict, ranked: list, related: list) -> dict:
    all_chunks = ranked[:TOP_K] + related

    chunk_map = {}
    for chunk in all_chunks:
        chunk_id = chunk.get("chunk_id")
        if chunk_id:
            chunk_map[chunk_id] = chunk

    enriched = []
    seen_ids = set()
    seen_urls = set()

    for c in answer.get("citations", []):
        source_id = (c.get("source_id") or "").strip()
        if not source_id or source_id in seen_ids:
            continue
        if _looks_like_non_chunk_source_id(source_id):
            continue

        seen_ids.add(source_id)
        chunk = chunk_map.get(source_id)
        if not chunk:
            continue

        metadata = chunk.get("metadata", {}) or {}

        raw_title = (
            metadata.get("citation_title")
            or metadata.get("section_title")
            or metadata.get("source_page")
            or metadata.get("title")
            or ""
        )
        title = (raw_title or "").strip()
        if not title or title.lower() == "untitled":
            title = _humanize_chunk_id_for_title(source_id)

        url = metadata.get("source_url") or metadata.get("url") or ""
        url = clean_url(url)
        if not url:
            continue

        if url in seen_urls:
            continue
        seen_urls.add(url)

        enriched.append(
            {
                "source_id": source_id,
                "title": title,
                "url": url,
            }
        )

    answer["citations"] = enriched
    return answer

# ═══════════════════════════════════════════════════════════════
# STEP 9 — VALIDATE ANSWER
# IMPORTANT:
# Confidence is set by Python, not trusted from LLM.
# ═══════════════════════════════════════════════════════════════

def validate_answer(answer: dict) -> dict:
    flags = answer.get("commercial_flags", {}) or {}

    if flags.get("contains_final_quote"):
        return {"valid": False, "reason": "contains_final_quote"}

    if flags.get("contains_hard_promise"):
        return {"valid": False, "reason": "contains_hard_promise"}

    # If model returned no citations on a non-advisory answer, downgrade style only.
    # DO NOT destroy Python-computed confidence.
    citations = answer.get("citations", [])
    if not citations and answer.get("answer_style") != "advisory":
        answer["answer_style"] = "low_confidence"

    cleaned_suggestions = []
    for s in answer.get("suggestions", []):
        s_type = s.get("type")
        tax = s.get("taxonomy_key")

        if s_type not in VALID_SUGGESTION_TYPES:
            continue

        if s_type == "meeting":
            cleaned_suggestions.append({
                "type": "meeting",
                "label": s.get("label", "Book a Technical Call"),
                "taxonomy_key": None
            })
            continue

        # IMPORTANT: allow question suggestions without taxonomy
        if s_type == "question":
            cleaned_suggestions.append({
                "type": "question",
                "label": s.get("label", "Tell me more"),
                "taxonomy_key": None
            })
            continue

        if tax in VALID_TAXONOMY_KEYS:
            cleaned_suggestions.append(s)

    answer["suggestions"] = cleaned_suggestions

    return {"valid": True, "answer": answer}


# ═══════════════════════════════════════════════════════════════
# STEP 10 — FALLBACK HANDLER
# ═══════════════════════════════════════════════════════════════

def handle_fallback(question: str, classification: dict) -> dict:
    if classification.get("is_out_of_scope"):
        message = (
            "I’m mainly here to help with A'sTechware’s services — AI agents, custom platforms, "
            "integrations, case studies, and delivery approach. If you want, tell me what you’re "
            "trying to build and I can point you in the right direction."
        )
    else:
        message = (
            "I don't have enough information to answer that confidently. "
            "For detailed answers specific to your situation, book a free "
            "30-minute technical call with the A'sTechware team."
        )

    return {
        "answer_markdown": message,
        "answer_style": "low_confidence",
        "citations": [],
        "suggestions": [
            {
                "type": "meeting",
                "label": "Book a 30-Min Technical Call",
                "taxonomy_key": None
            }
        ],
        "confidence": 0.0,
        "needs_clarification": False,
        "clarifying_question": None,
        "commercial_flags": {}
    }


# ═══════════════════════════════════════════════════════════════
# CONFIDENCE SCORING
# Separate from ranking.
# This is why hybrid won't collapse to tiny confidence anymore.
# ═══════════════════════════════════════════════════════════════

def compute_confidence_score(ranked: list, classification: dict) -> float:
    """
    Build a normalized 0.0–1.0 confidence score for answer-generation policy.
    This is separate from hybrid ranking score (RRF-based).

    Key idea:
    - final_score / rrf_score are ranking signals, NOT confidence directly
    - confidence should mainly use vector similarity + lexical support + topic overlap
    """
    if not ranked:
        return 0.0

    top = ranked[0]
    metadata = top.get("metadata", {}) or {}
    question_topics = set(normalize_topics(classification.get("topics", [])))
    chunk_topics = set(normalize_topics(metadata.get("topics", [])))
    overlap = len(question_topics & chunk_topics)

    # Signals
    vector_sim = top.get("similarity", 0.0)          # 0.0–1.0-ish
    lexical = top.get("lexical_score", 0.0)          # ts_rank_cd usually small
    sources = set(top.get("sources", []))
    is_verified = metadata.get("knowledge_type") == "verified"

    # Normalize lexical score into 0–1 (aggressive cap)
    lexical_norm = min(lexical / 0.35, 1.0) if lexical else 0.0

    confidence = 0.0

    # Vector similarity = strongest signal
    confidence += min(vector_sim, 1.0) * 0.62

    # Lexical support
    confidence += lexical_norm * 0.12

    # Found by both retrieval methods = stronger evidence
    if "vector" in sources and "fts" in sources:
        confidence += 0.10

    # Topic overlap (max 3)
    confidence += min(overlap, 3) * 0.05

    # Verified content
    if is_verified:
        confidence += 0.04

    # Multiple supporting chunks
    if len(ranked) >= 3:
        confidence += 0.04

    return round(min(confidence, 1.0), 3)


# ═══════════════════════════════════════════════════════════════
# MIXED-SCOPE HANDLING
# Example: "cricket and HIPAA"
# ═══════════════════════════════════════════════════════════════

def build_scope_note(classification: dict) -> str:
    """
    Builds a short note for mixed-scope questions.
    Example:
    'I can help with the HIPAA part, but cricket is outside the scope...'
    """
    if not classification.get("partially_in_scope"):
        return ""

    topics = classification.get("topics", []) or []
    out_terms = classification.get("out_of_scope_terms", []) or []

    topic_label = ", ".join([pretty_topic_label(t) for t in topics[:2]])
    out_label = ", ".join(out_terms[:2])

    if topic_label and out_label:
        return (
            f"I can help with the {topic_label} part — that's within "
            f"A'sTechware's knowledge base. {out_label} is outside what "
            f"this assistant covers, so I'll focus on the relevant part.\n\n"
        )

    if out_label:
        return (
            f"Part of your question is outside what this assistant covers ({out_label}), "
            f"so I'll answer only the relevant part.\n\n"
        )

    return "Your question mixes healthcare and unrelated topics, so I’ll answer only the healthcare-related part.\n\n"


# ═══════════════════════════════════════════════════════════════
# RAG PIPELINE (EXTRACTED FROM YOUR ORIGINAL run_pipeline)
# This keeps your retrieval core intact.
# ═══════════════════════════════════════════════════════════════

def run_rag_pipeline(
    user_question: str,
    verbose: bool = True,
    router_result: Optional[dict] = None,
    *,
    generate_answer_question: Optional[str] = None,
    rag_extra_context: Optional[str] = None,
    rag_plus_web_generation: bool = False,
) -> dict:
    log_timing("run_rag_pipeline_enter")
    # Step 1: Classify
    print("\n  Step 1 → Classifying...")
    with time_block("run_rag_step1_classify_question"):
        classification = classify_question(user_question)

    if verbose:
        print(f"    category  : {classification['primary_category']}")
        print(f"    topics    : {classification['topics']}")
        print(f"    intent    : {classification['intent']}")
        print(f"    negative  : {classification['is_negative']}")
        print(f"    partial   : {classification.get('partially_in_scope', False)}")
        print(f"    out_terms : {classification.get('out_of_scope_terms', [])}")
        print(f"    reworded  : {classification['reformulated']}")

    # Fully out-of-scope only
    if classification.get("is_out_of_scope"):
        print("  → Out of scope, returning fallback")
        log_timing("run_rag_pipeline_exit", detail="fallback_out_of_scope")
        return handle_fallback(user_question, classification)

    # Step 2: Filters
    print("\n  Step 2 → Building filters...")
    with time_block("run_rag_step2_build_filters"):
        filters = build_filters(classification)
    if verbose:
        print(f"    filters   : {filters}")

    # Step 3: Embed (timing inside embed_text → openai_embeddings)
    print("\n  Step 3 → Embedding question...")
    search_text = classification.get("reformulated", user_question)
    embedding = embed_text(search_text)
    if verbose:
        print(f"    dims      : {len(embedding)}")

    # Step 4: Hybrid Search (timing inside search_supabase_vector / _fts)
    print("\n  Step 4 → Hybrid search (Vector + FTS)...")
    with time_block("run_rag_step4_search_hybrid"):
        raw_results = search_hybrid(search_text, embedding, filters)
    print(f"    found     : {len(raw_results)} raw fused matches")

    if not raw_results:
        print("  → No matches anywhere, returning fallback")
        log_timing("run_rag_pipeline_exit", detail="fallback_no_hybrid_matches")
        return handle_fallback(user_question, classification)

    # Step 5: Re-rank
    print("\n  Step 5 → Re-ranking...")
    with time_block("run_rag_step5_rerank_results"):
        ranked = rerank_results(raw_results, classification)

    proof_query = is_proof_query(user_question)

    if proof_query and not has_case_study_in_top(ranked, 5):
        print("  → Proof query detected but no case study in top results, retrying with case-study-first filter")
        forced_filters = dict(filters)
        forced_filters["categories"] = ["case_study", "service_capability"]

        with time_block("run_rag_proof_query_retry_hybrid_rerank"):
            retry_results = search_hybrid(search_text, embedding, forced_filters)
            if retry_results:
                retry_ranked = rerank_results(retry_results, classification)
                if has_case_study_in_top(retry_ranked, 5):
                    ranked = retry_ranked

    top_score = ranked[0]["final_score"] if ranked else 0.0
    confidence_score = compute_confidence_score(ranked, classification)

    if verbose:
        for r in ranked[:5]:
            print(
                f"    {r['chunk_id']:<45} "
                f"{r['final_score']:.3f} "
                f"(sim={r.get('similarity', 0):.3f}, "
                f"lex={r.get('lexical_score', 0):.3f}, "
                f"conf≈{confidence_score:.3f}, "
                f"sources={','.join(r.get('sources', []))})"
            )

    # IMPORTANT:
    # final_score is RRF-based and much smaller than vector similarity.
    # Do NOT compare it to LOW_CONFIDENCE (0.40). Use a small threshold.
    if top_score < 0.02:
        print(f"  → Top score {top_score:.3f} below hybrid threshold, returning fallback")
        log_timing("run_rag_pipeline_exit", detail="fallback_low_top_score")
        return handle_fallback(user_question, classification)

    # Step 6: Context
    print("\n  Step 6 → Building context...")
    with time_block("run_rag_step6_fetch_related_and_build_context"):
        related = fetch_related_chunks(ranked)
        context = build_context(ranked, related, classification)
        if rag_extra_context:
            context = rag_extra_context.strip() + "\n\n" + context

    if verbose:
        print(f"    direct chunks  : {min(len(ranked), TOP_K)}")
        print(f"    related chunks : {len(related)}")

    # Optional verbose debug
    if verbose:
        print("\n" + "═" * 60)
        print("  CONTEXT SENT TO GPT")
        print("═" * 60)
        print(context)

        print("\n" + "═" * 60)
        print("  CLASSIFICATION")
        print("═" * 60)
        print(json.dumps(classification, indent=2))

        print("\n" + "═" * 60)
        print("  CONFIDENCE SCORE")
        print("═" * 60)
        print(f"  confidence_score : {confidence_score}")
        print(f"  HIGH_CONFIDENCE  : {HIGH_CONFIDENCE}")
        print(f"  MEDIUM_CONFIDENCE: {MEDIUM_CONFIDENCE}")
        print(f"  LOW_CONFIDENCE   : {LOW_CONFIDENCE}")
        print(f"  level            : {'HIGH' if confidence_score >= HIGH_CONFIDENCE else 'MEDIUM' if confidence_score >= MEDIUM_CONFIDENCE else 'LOW'}")

    # Step 7: Generate (timing inside generate_answer → openai_chat gpt-4o)
    print("\n  Step 7 → Generating answer...")
    q_for_answer = (generate_answer_question or "").strip() or user_question
    with time_block("run_rag_step7_generate_answer_total"):
        answer = generate_answer(
            q_for_answer,
            context,
            classification,
            confidence_score,
            rag_plus_web_generation=rag_plus_web_generation,
        )

    # Always trust Python confidence, not model confidence
    answer["confidence"] = confidence_score

    # Mixed-scope handling
    scope_note = build_scope_note(classification)
    if scope_note:
        answer["answer_markdown"] = scope_note + answer.get("answer_markdown", "")
        if answer.get("answer_style") == "direct":
            answer["answer_style"] = "clarifying"

    # Step 8: Enrich citations
    print("\n  Step 8 → Enriching citations...")
    with time_block("run_rag_step8_enrich_citations"):
        answer = enrich_citations(answer, ranked, related)

    # Step 9: Validate
    print("\n  Step 9 → Validating...")
    with time_block("run_rag_step9_validate_answer"):
        validation = validate_answer(answer)

    if not validation["valid"]:
        print(f"  → Validation failed: {validation['reason']} — regenerating once")
        with time_block("run_rag_step7_generate_answer_retry"):
            answer = generate_answer(
                q_for_answer,
                context,
                classification,
                confidence_score,
                rag_plus_web_generation=rag_plus_web_generation,
            )

        # Re-apply Python confidence after regeneration
        answer["confidence"] = confidence_score

        # Re-apply mixed-scope note after regeneration
        scope_note = build_scope_note(classification)
        if scope_note:
            answer["answer_markdown"] = scope_note + answer.get("answer_markdown", "")
            if answer.get("answer_style") == "direct":
                answer["answer_style"] = "clarifying"

        with time_block("run_rag_step8_enrich_citations_retry"):
            answer = enrich_citations(answer, ranked, related)
        with time_block("run_rag_step9_validate_answer_retry"):
            validation = validate_answer(answer)

        if not validation["valid"]:
            print("  → Still failed after retry, returning fallback")
            log_timing("run_rag_pipeline_exit", detail="fallback_validation_failed")
            return handle_fallback(user_question, classification)

    final = validation["answer"]

    print(f"\n  ✓ Answer ready | style: {final['answer_style']} | confidence: {final['confidence']}")
    print(f"\n  ANSWER PREVIEW:\n  {final['answer_markdown'][:300]}...")
    log_timing("run_rag_pipeline_exit_ok")

    return final


# ═══════════════════════════════════════════════════════════════
# MASTER PIPELINE V2
# New orchestration layer
# ═══════════════════════════════════════════════════════════════

def run_pipeline(
    user_question: str,
    verbose: bool = True,
    *,
    current_user_message: Optional[str] = None,
) -> dict:
    log_timing("run_pipeline_enter")
    try:
        return _run_pipeline_impl(
            user_question,
            verbose=verbose,
            current_user_message=current_user_message,
        )
    finally:
        log_timing("run_pipeline_exit")


def _run_pipeline_impl(
    user_question: str,
    verbose: bool = True,
    *,
    current_user_message: Optional[str] = None,
) -> dict:
    print(f"\n{'═' * 60}")
    print(f"  Q: {user_question}")
    print(f"{'═' * 60}")

    # --------------------------------------------------
    # STAGE 0: Long input guard (single turn only when current_user_message is set)
    # --------------------------------------------------
    long_input_text = (current_user_message or "").strip() or user_question
    if should_escalate_long_input(long_input_text):
        print("  → Long input detected (>500 words on this message), recommending technical call")
        log_timing("run_pipeline_return", detail="stage0_long_input")
        return handle_long_input_escalation()

    # --------------------------------------------------
    # STAGE 1: AI Router (OpenAI timing logged inside route_query)
    # --------------------------------------------------
    print("\n  Stage 1 → Routing...")
    router_result = route_query(user_question)
    route = router_result.get("route", "rag_only")

    if verbose:
        print(f"    route     : {route}")
        print(f"    router    : {json.dumps(router_result, ensure_ascii=False)}")

    # --------------------------------------------------
    # STAGE 1b: Public contact (email / phone) — deterministic, overrides router
    # Use the same single-turn text as the long-input guard (not user_question with history):
    # e.g. prior replies may say "phone tag" + "A'sTechware" and wrongly satisfy phone_hit.
    # --------------------------------------------------
    contact_probe = (current_user_message or "").strip() or user_question
    ckind = contact_info_intent(contact_probe)
    if ckind:
        print(f"  → Contact info shortcut ({ckind})")
        log_timing("run_pipeline_return", detail="stage1b_contact_info")
        return handle_contact_info_route(ckind)

    # --------------------------------------------------
    # STAGE 2: Route handling
    # --------------------------------------------------
    if route == "greeting":
        print("  → Greeting route")
        log_timing("run_pipeline_return", detail="stage2_greeting")
        return handle_greeting_route(router_result)

    if route == "out_of_scope":
        print("  → Out-of-scope route")
        log_timing("run_pipeline_return", detail="stage2_out_of_scope")
        return handle_out_of_scope_route()

    # --------------------------------------------------
    # STAGE 3A: RAG ONLY
    # --------------------------------------------------
    if route == "rag_only":
        print("  → RAG-only route")
        log_timing("run_pipeline_branch", detail="stage3a_rag_only_entering_run_rag")
        return run_rag_pipeline(user_question, verbose=verbose, router_result=router_result)

    # --------------------------------------------------
    # STAGE 3C: RAG + WEB
    # --------------------------------------------------
    if route == "rag_plus_web":
        print("  → RAG + Web route")
        urls = extract_urls(user_question)
        print(urls)

        if not urls:
            print("  → Router chose rag_plus_web but no URL found, falling back to RAG")
            log_timing("run_pipeline_branch", detail="stage3c_rag_plus_web_no_url_fallback_rag")
            return run_rag_pipeline(user_question, verbose=verbose, router_result=router_result)

        web_context = fetch_external_website_context(urls, user_input=user_question)
        print(web_context)
        website_summary = summarize_external_website(user_question, web_context)

        implementation_brief = build_ai_implementation_brief(
            user_input=user_question,
            website_summary=website_summary,
            web_context=web_context
        )

        derived_query = (
            implementation_brief.get("derived_rag_query")
            or website_summary.get("derived_rag_query")
            or user_question
        )

        rag_extra = _build_rag_plus_web_evidence_block(
            website_summary,
            implementation_brief,
            web_context,
        )

        rag_result = run_rag_pipeline(
            derived_query,
            verbose=verbose,
            router_result=router_result,
            generate_answer_question=user_question,
            rag_extra_context=rag_extra,
            rag_plus_web_generation=True,
        )

        log_timing("run_pipeline_return", detail="stage3c_rag_plus_web_combined")
        return generate_combined_answer_with_web_and_rag(
            user_input=user_question,
            router_result=router_result,
            website_summary=website_summary,
            implementation_brief=implementation_brief,
            rag_result=rag_result,
        )

    # Safety fallback
    print("  → Unknown route, defaulting to RAG")
    log_timing("run_pipeline_branch", detail="stage3_unknown_route_fallback_rag")
    return run_rag_pipeline(user_question, verbose=verbose, router_result=router_result)


# ═══════════════════════════════════════════════════════════════
# CLI TEST ENTRYPOINT
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    # CLI wrapper so Rails/other services can call this pipeline as an API.
    # Usage (recommended from Rails):
    #   python3 cursor-final-pipeline1-1.py --question "..."
    #
    # Or pass JSON via stdin:
    #   echo '{"question":"..."}' | python3 cursor-final-pipeline1-1.py

    import argparse
    import contextlib

    # Anchor cumulative timings from the moment the interpreter enters this script path.
    pipeline_timer_reset()
    log_timing("python_cli_entry", detail="__main__ started")

    TEST_QUESTION = "what about implementing google ads?"

    parser = argparse.ArgumentParser()
    parser.add_argument("--question", type=str, default=None)
    args = parser.parse_args()

    question = (args.question or "").strip()
    current_user_message: Optional[str] = None
    if not question:
        raw = sys.stdin.read().strip()
        if raw:
            try:
                payload = json.loads(raw)
                question = (payload.get("question") or payload.get("message") or "").strip()
                cu = (payload.get("current_user_message") or "").strip()
                if cu:
                    current_user_message = cu
            except Exception:
                question = ""

    if not question:
        question = TEST_QUESTION

    q_preview = question if len(question) <= 100 else question[:97] + "..."
    log_timing("python_cli_question_ready", detail=f"len={len(question)} q={q_preview!r}")

    try:
        # Redirect all existing prints (debug logs) to stderr so docker logs can show them,
        # while keeping stdout reserved for final JSON (Rails parses stdout).
        with contextlib.redirect_stdout(sys.stderr):
            result = run_pipeline(
                question,
                verbose=True,
                current_user_message=current_user_message,
            )

        log_timing("python_cli_before_stdout_json", detail="about to write JSON to stdout")
        sys.stdout.write(json.dumps(result, ensure_ascii=False) + "\n")
    except Exception as e:
        # Always emit JSON on stdout for the caller.
        sys.stdout.write(json.dumps({"error": str(e)}, ensure_ascii=False) + "\n")
        sys.exit(1)