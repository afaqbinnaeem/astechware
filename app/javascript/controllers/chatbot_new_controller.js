import { Controller } from "@hotwired/stimulus"

// Vanilla JS implementation of the "new" chatbot UI.
// The repo currently uses Rails importmap + Sprockets, so JSX/React isn't wired up.
// This controller keeps the same UX/flow as `astechware-chatbot.jsx`:
// - ask AI via a new backend endpoint
// - show lead form after a few exchanges
// - submit lead to the new backend endpoint
export default class extends Controller {
  static values = {
    recaptchaSiteKey: String,
  }

  connect() {
    this.isMobile = this.isMobileDevice()

    // Persist chat open/close state across page navigation
    const savedState = window.localStorage.getItem("astw_chatbot_open")
    this.isOpen = savedState === null ? true : savedState === "true"

    this.defaultWelcomeMessages = [
      {
        role: "assistant",
        content:
          "Hello! I'm here to help you learn about A'sTechware. What would you like to know?",
      },
    ]
    this.messages = [...this.defaultWelcomeMessages]
    this.isLoading = false
    this.showLeadForm = false
    this.leadSubmitted = false
    this.messageCount = 0
    this.pendingLeadTimer = null
    this.suppressScroll = false

    this.recaptchaEnabled = !!(this.recaptchaSiteKeyValue && this.recaptchaSiteKeyValue.trim())
    this.recaptchaVerified = false
    this.recaptchaVerifiedOnce = false
    this.recaptchaWidgetId = null
    this.hasSentFirstMessage = false

    // Load after page render
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        setTimeout(() => {
          this.render()
          this.updateVisibility()
          this.scrollToBottom()
          this.renderSuggestedPromptsIfNeeded()
          this.loadPersistedHistory()
          this.initRecaptchaIfNeeded()
        }, 800)
      })
    })
  }

  isMobileDevice() {
    // Mirror the old chat controller's heuristic.
    return (
      window.innerWidth <= 576 ||
      /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
        navigator.userAgent
      )
    )
  }

  // ---- DOM rendering ----

  render() {
    this.element.innerHTML = `
      <div style="font-family: 'DM Sans', sans-serif; width: 100%; max-width: 440px; margin: 0 auto;">
        <div
          id="astw-chatbot-launcher"
          style="display: ${this.isOpen ? "none" : "flex"}; justify-content: flex-end; position: fixed; bottom: 24px; right: 24px; z-index: 9999; max-width: min(280px, calc(100vw - 48px));"
        >
          <button
            type="button"
            id="astw-chatbot-bubble"
            aria-label="Open A'sTechware AI Consultant chat"
            style="font-family: inherit; font-size: 13px; font-weight: 700; color: #022c22; background: linear-gradient(135deg, #10b981, #059669); border: none; border-radius: 999px; padding: 12px 18px; cursor: pointer; box-shadow: 0 8px 28px rgba(16,185,129,0.45), 0 2px 8px rgba(0,0,0,0.25); line-height: 1.25; text-align: center; letter-spacing: -0.02em; transition: transform 0.2s, box-shadow 0.2s;"
          >
            A'sTechware AI Consultant
          </button>
        </div>

        <div id="astw-chatbot-panel" style="display: ${this.isOpen ? "flex" : "none"}; flex-direction: column; background: linear-gradient(180deg, #041f17 0%, #071f16 50%, #0a251b 100%); border-radius: 20px; border: 1px solid rgba(16,185,129,0.15); box-shadow: 0 24px 80px rgba(0,0,0,0.5), 0 0 60px rgba(16,185,129,0.08); overflow: hidden; position: fixed; bottom: 20px; right: 20px; z-index: 9999; width: calc(100vw - 40px); max-width: 440px; height: min(680px, calc(100vh - 40px));">
          <div style="padding: 18px 20px; background: linear-gradient(135deg, rgba(16,185,129,0.12) 0%, rgba(5,150,105,0.06) 100%); border-bottom: 1px solid rgba(16,185,129,0.12); display: flex; align-items: center; gap: 14px; flex-shrink: 0;">
            <div style="width: 42px; height: 42px; border-radius: 12px; background: linear-gradient(135deg, #10b981, #059669); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 800; color: #022c22; flex-shrink: 0;">
              A'
            </div>
            <div style="flex: 1; display: flex; flex-direction: column; align-items: flex-start; justify-content: center;">
              <div style="font-size: 15px; font-weight: 700; color: #f0fdf4; letter-spacing: -0.01em; line-height: 1.15; margin-bottom: 2px;">A'sTechware AI Consultant</div>
              <div style="font-size: 12px; color: #6ee7b7; margin-top: 6px; display: flex; align-items: center; gap: 5px; line-height: 1.2;">
                <span style="width: 6px; height: 6px; border-radius: 50%; background: #10b981; display: inline-block;"></span>
                Online — AI & Automation Expert
              </div>
            </div>
            <button type="button" id="astw-chatbot-close" style="background: none; border: none; color: rgba(255,255,255,0.4); cursor: pointer; padding: 4px; font-size: 20px; line-height: 1;">✕</button>
          </div>

          <div id="astw-chatbot-messages" style="flex: 1; overflow-y: auto; padding: 20px 16px 12px; display: flex; flex-direction: column; gap: 4;">
            <div id="astw-chatbot-message-list" style="display:flex; flex-direction:column; gap:4px;">
              <div id="astw-chatbot-message-items" style="display:flex; flex-direction:column; gap:4px;"></div>
              <div id="astw-chatbot-suggested" style="${this.messages.length === 1 ? "display: flex;" : "display: none;"}; flex-direction: column; gap: 8px; margin-top: 12px; animation: fadeSlideIn 0.5s ease-out 0.3s both; padding-left: 42px;"></div>
              <div id="astw-chatbot-lead-mount" style="display: none; margin-left: 42px; animation: fadeSlideIn 0.4s ease-out;"></div>
              <div id="astw-chatbot-loader" style="display: none;">
                <div style="display:flex; justify-content:flex-start; margin-bottom:6px; animation: fadeSlideIn 0.3s ease-out;">
                  <div style="width: 32px; height: 32px; border-radius: 10px; background: linear-gradient(135deg, #10b981, #059669); display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-right: 10px; margin-top: 2px; font-size: 14px; font-weight: 800; color: #022c22;">A</div>
                  <div style="max-width: 78%; padding: 14px 18px; border-radius: 18px 18px 18px 4px; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.08);">
                    <div style="display:flex; gap:6px; align-items:center;">
                      <span style="width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation: astw-bounce 1.2s ease-in-out infinite 0s;"></span>
                      <span style="width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation: astw-bounce 1.2s ease-in-out infinite 0.15s;"></span>
                      <span style="width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation: astw-bounce 1.2s ease-in-out infinite 0.3s;"></span>
                    </div>
                  </div>
                </div>
              </div>
              <div id="astw-chatbot-end" style="height: 1px;"></div>
            </div>
          </div>

          <div style="padding: 12px 16px 16px; border-top: 1px solid rgba(255,255,255,0.06); background: rgba(0,0,0,0.2); flex-shrink: 0;">
            <div id="astw-recaptcha-wrap" style="display:none; padding: 10px 0 12px;">
              <div style="font-size: 12px; color: rgba(255,255,255,0.55); margin-bottom: 10px;">
                Please verify you’re human to start the chat.
              </div>
              <div id="astw-recaptcha"></div>
              <div id="astw-recaptcha-error" style="display:none; margin-top: 8px; font-size: 12px; color: #fca5a5;"></div>
            </div>
            <div style="display: flex; gap: 8px; align-items: flex-end;">
              <textarea
                id="astw-chatbot-input"
                rows="1"
                style="flex: 1; padding: 12px 16px; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); border-radius: 14px; color: #e2e8f0; font-size: 14px; font-family: inherit; resize: none; line-height: 1.5; transition: border-color 0.2s, box-shadow 0.2s; overflow: hidden;"
                placeholder="Describe your business or ask anything..."></textarea>
              <button id="astw-chatbot-send" type="button" disabled style="width: 44px; height: 44px; border-radius: 14px; background: rgba(255,255,255,0.06); border: none; cursor: default; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.25)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="22" y1="2" x2="11" y2="13" />
                  <polygon points="22 2 15 22 11 13 2 9 22 2" />
                </svg>
              </button>
            </div>
            <div style="text-align: center; margin-top: 10px; font-size: 11px; color: rgba(255,255,255,0.38); line-height: 1.35;">
              A'sTechware AI Consultant can make mistakes. For important info,
              <a href="https://calendly.com/ahmadkamran/new-meeting" target="_blank" rel="noopener noreferrer" style="color:#6ee7b7;text-decoration:underline;">schedule a meeting</a>.
             </div>
            <div style="text-align: center; margin-top: 8px; font-size: 11px; color: rgba(255,255,255,0.2);">
              Powered by <span style="color:#6ee7b7;font-weight:600;">A'sTechware</span> · AI & Platform Engineering
            </div>
          </div>
        </div>
      </div>

      <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;0,9..40,800&display=swap');
        @keyframes astw-bounce { 0%,60%,100% { transform: translateY(0); opacity: .4; } 30% { transform: translateY(-6px); opacity: 1; } }
        @keyframes fadeSlideIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }

        /* Chat scrollbar styling */
        #astw-chatbot-messages {
          scrollbar-width: thin;
          scrollbar-color: rgba(110,231,183,0.35) rgba(255,255,255,0.06);
        }
        #astw-chatbot-messages::-webkit-scrollbar {
          width: 6px;
        }
        #astw-chatbot-messages::-webkit-scrollbar-track {
          background: rgba(255,255,255,0.06);
          border-radius: 10px;
        }
        #astw-chatbot-messages::-webkit-scrollbar-thumb {
          background: rgba(110,231,183,0.25);
          border-radius: 10px;
          border: 1px solid rgba(255,255,255,0.08);
        }
        #astw-chatbot-messages::-webkit-scrollbar-thumb:hover {
          background: rgba(110,231,183,0.4);
        }
      </style>
    `

    this.launcherEl = this.element.querySelector("#astw-chatbot-launcher")
    this.bubbleEl = this.element.querySelector("#astw-chatbot-bubble")
    this.panelEl = this.element.querySelector("#astw-chatbot-panel")
    this.closeBtnEl = this.element.querySelector("#astw-chatbot-close")
    this.messagesEl = this.element.querySelector("#astw-chatbot-messages")
    this.messageListEl = this.element.querySelector("#astw-chatbot-message-list")
    this.messageItemsEl = this.element.querySelector("#astw-chatbot-message-items")
    this.loaderEl = this.element.querySelector("#astw-chatbot-loader")
    this.suggestedEl = this.element.querySelector("#astw-chatbot-suggested")
    this.leadMountEl = this.element.querySelector("#astw-chatbot-lead-mount")
    this.endEl = this.element.querySelector("#astw-chatbot-end")

    this.inputEl = this.element.querySelector("#astw-chatbot-input")
    this.sendBtnEl = this.element.querySelector("#astw-chatbot-send")

    this.hydrateMessageList()

    this.bubbleEl?.addEventListener("click", () => {
      this.isOpen = true
      window.localStorage.setItem("astw_chatbot_open", "true")
      this.updateVisibility()
    })
    
    this.closeBtnEl?.addEventListener("click", () => {
      this.isOpen = false
      window.localStorage.setItem("astw_chatbot_open", "false")
      this.updateVisibility()
    })

    this.inputEl?.addEventListener("input", () => this.onInputChange())
    this.sendBtnEl?.addEventListener("click", () => this.sendMessage())
    this.inputEl?.addEventListener("keydown", (e) => this.onKeyDown(e))
  }

  renderMessageBubble({ role, content }) {
    const isUser = role === "user"
    const align = isUser ? "flex-end" : "flex-start"

    const bubbleStyle = isUser
      ? "linear-gradient(135deg, #10b981, #059669)"
      : "rgba(255,255,255,0.06)"

    const textColor = isUser ? "#022c22" : "#e2e8f0"
    const border = isUser ? "none" : "1px solid rgba(255,255,255,0.08)"
    const borderRadius = isUser ? "18px 18px 4px 18px" : "18px 18px 18px 4px"
    const fontWeight = isUser ? "600" : "400"

    const avatarHtml = isUser
      ? ""
      : `<div style="width: 32px; height: 32px; border-radius: 10px; background: linear-gradient(135deg, #10b981, #059669); display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-right: 10px; margin-top: 2px; font-size: 14px; font-weight: 800; color: #022c22;">A</div>`

    return `
      <div style="display:flex; justify-content:${align}; margin-bottom:6px; animation: fadeSlideIn 0.3s ease-out;">
        ${avatarHtml}
        <div style="
          max-width: 78%;
          padding: 14px 18px;
          border-radius: ${borderRadius};
          background: ${bubbleStyle};
          color: ${textColor};
          font-size: 14px;
          line-height: 1.65;
          font-weight: ${fontWeight};
          border: ${border};
          white-space: pre-wrap;
          word-break: break-word;
        ">${this.renderMarkdownLiteToHtml(content)}</div>
      </div>
    `
  }

  appendMessageBubble({ role, content, meta }) {
    const isUser = role === "user"
    const bubbleHtml = this.renderMessageBubble({ role, content })

    // RenderMessageBubble includes content; still re-inject for consistency.
    const tmp = document.createElement("div")
    tmp.innerHTML = bubbleHtml
    const wrapper = tmp.firstElementChild
    const contentDiv = wrapper.querySelector("div[style*='max-width']")
    contentDiv.innerHTML = this.renderMarkdownLiteToHtml(content)

    // Always insert new messages above the loader so the loader appears beneath the latest user message.
    const insertBeforeEl = null
    const parent = this.messageItemsEl || this.messageListEl || this.messagesEl
    parent.insertBefore(wrapper, insertBeforeEl)
    if (!this.suppressScroll) this.scrollElementIntoView(wrapper)

    if (role === "assistant" && meta) {
      this.appendAssistantMeta(wrapper, meta)
    }

    // Hide suggested prompts once user chats.
    if (this.messages.length > 1) {
      this.suggestedEl.style.display = "none"
    }

    return wrapper
  }

  hydrateMessageList() {
    if (!this.messageItemsEl) return
    this.messageItemsEl.innerHTML = ""

    const prevSuppress = this.suppressScroll
    this.suppressScroll = true
    try {
      this.messages.forEach((m) => {
        this.appendMessageBubble(m)
      })
    } finally {
      this.suppressScroll = prevSuppress
    }

    // Suggested prompts should only show when we have exactly the default welcome state.
    const isWelcomeOnly =
      this.messages.length === this.defaultWelcomeMessages.length &&
      this.messages[0]?.role === "assistant" &&
      this.messages[0]?.content === this.defaultWelcomeMessages[0]?.content

    if (this.suggestedEl) {
      this.suggestedEl.style.display = isWelcomeOnly ? "flex" : "none"
    }
  }

  async loadPersistedHistory() {
    try {
      const resp = await fetch("/chat/history_new", {
        headers: { "Accept": "application/json" },
        credentials: "same-origin",
      })
      const data = await resp.json()
      if (!resp.ok || data.error) return

      const msgs = Array.isArray(data.messages) ? data.messages : []
      const normalized = msgs
        .filter((m) => m && (m.role === "user" || m.role === "assistant") && m.content)
        .map((m) => ({
          role: m.role,
          content: m.content,
          meta: m.meta || null,
        }))

      if (normalized.length > 0) {
        // Always keep the hard-coded welcome message at the top.
        const historyOnly = normalized

        // Only show meta (citations/suggestions/etc.) under the last assistant message.
        let lastAssistantIdx = -1
        for (let i = historyOnly.length - 1; i >= 0; i--) {
          if (historyOnly[i].role === "assistant") {
            lastAssistantIdx = i
            break
          }
        }

        const withMetaOnlyOnLast = historyOnly.map((m, idx) => {
          if (m.role !== "assistant") return m
          if (idx === lastAssistantIdx) return m
          return { ...m, meta: null }
        })

        this.messages = [...this.defaultWelcomeMessages, ...withMetaOnlyOnLast]

        // Re-render to show persisted conversation
        this.hydrateMessageList()
        this.scrollToBottom()
      }
    } catch (_e) {
      // ignore
    }
  }

  appendAssistantMeta(wrapper, meta) {
    const citations = Array.isArray(meta.citations) ? meta.citations : []
    const suggestions = Array.isArray(meta.suggestions) ? meta.suggestions : []

    if (citations.length === 0 && suggestions.length === 0) return

    // Render meta as part of the same assistant bubble (footer section)
    const bubble = wrapper.querySelector("div[style*='max-width']")
    if (!bubble) return

    // Ensure only one meta section exists at a time (latest assistant message).
    this.element.querySelectorAll(".astw-assistant-meta").forEach((el) => el.remove())

    const metaWrap = document.createElement("div")
    metaWrap.className = "astw-assistant-meta"
    metaWrap.style.cssText =
      "margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.10); display:flex; flex-direction:column; gap: 10px;"

    if (citations.length > 0) {
      const cites = document.createElement("div")
      cites.style.cssText = "display:flex; flex-direction:column; gap: 6px;"

      const title = document.createElement("div")
      title.textContent = "Sources"
      title.style.cssText = "font-size: 11px; color: rgba(255,255,255,0.45); text-transform: uppercase; letter-spacing: 0.08em; font-weight: 800;"
      cites.appendChild(title)

      const list = document.createElement("div")
      list.style.cssText = "display:flex; flex-direction:column; gap: 6px;"

      citations.slice(0, 5).forEach((c) => {
        const a = document.createElement("a")
        a.href = (c && c.url) ? c.url : "#"
        a.target = "_blank"
        a.rel = "noopener noreferrer"
        a.textContent = (c && (c.title || c.source_id)) ? (c.title || c.source_id) : "Source"
        a.style.cssText = "color: rgba(110,231,183,0.95); font-size: 12px; text-decoration: none; font-weight: 650;"
        a.addEventListener("mouseenter", () => (a.style.textDecoration = "underline"))
        a.addEventListener("mouseleave", () => (a.style.textDecoration = "none"))
        list.appendChild(a)
      })

      cites.appendChild(list)
      metaWrap.appendChild(cites)
    }

    if (suggestions.length > 0) {
      const sugWrap = document.createElement("div")
      sugWrap.style.cssText = "display:flex; flex-wrap: wrap; gap: 8px;"

      suggestions.slice(0, 4).forEach((s) => {
        const type = (s && s.type) ? String(s.type) : "question"
        const label = (s && s.label) ? String(s.label) : "Suggestion"

        if (type === "meeting") {
          const link = document.createElement("a")
          link.href = "https://calendly.com/ahmadkamran/new-meeting"
          link.target = "_blank"
          link.rel = "noopener noreferrer"
          link.textContent = label || "Book a Technical Call"
          link.style.cssText = "padding: 8px 12px; border-radius: 12px; background: rgba(16,185,129,0.18); border: 1px solid rgba(16,185,129,0.35); color: #6ee7b7; font-size: 12px; font-weight: 700; text-decoration:none;"
          sugWrap.appendChild(link)
          return
        }

        const btn = document.createElement("button")
        btn.type = "button"
        btn.textContent = label
        btn.style.cssText = "padding: 8px 12px; border-radius: 12px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.14); color: rgba(255,255,255,0.80); font-size: 12px; font-weight: 650; cursor:pointer; font-family: inherit;"
        btn.addEventListener("click", () => this.sendMessage(label))
        sugWrap.appendChild(btn)
      })

      metaWrap.appendChild(sugWrap)
    }

    bubble.appendChild(metaWrap)
  }

  renderMarkdownLiteToHtml(text) {
    const escapeHtml = (str) =>
      str
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;")

    const escaped = escapeHtml(String(text || ""))

    // Bold: **text**
    const bolded = escaped.replace(/\*\*(.+?)\*\*/g, (_m, inner) => {
      return `<strong style="color:#6ee7b7;font-weight:700">${inner}</strong>`
    })

    return bolded.replaceAll("\n", "<br/>")
  }

  // ---- UI state updates ----

  updateVisibility() {
    if (!this.panelEl) return
    if (this.launcherEl) {
      this.launcherEl.style.display = this.isOpen ? "none" : "flex"
    } else if (this.bubbleEl) {
      this.bubbleEl.style.display = this.isOpen ? "none" : "flex"
    }
    this.panelEl.style.display = this.isOpen ? "flex" : "none"
    if (this.isOpen) {
      this.inputEl?.focus()
    }
  }

  scrollToBottom() {
    this.endEl?.scrollIntoView({ behavior: "smooth", block: "end" })
  }

  scrollElementIntoView(el, opts = {}) {
    if (!el) return
    // Keep the viewport anchored around the latest interaction, not the absolute bottom.
    // This avoids the loader becoming partially hidden when the chat grows.
    const behavior = opts.behavior || "smooth"
    const block = opts.block || "end"
    el.scrollIntoView({ behavior, block })
  }

  onInputChange() {
    const val = this.inputEl.value || ""
    const gated = this.recaptchaEnabled && !this.recaptchaVerifiedOnce
    this.sendBtnEl.disabled = !val.trim() || this.isLoading || gated
    this.sendBtnEl.style.cursor = !val.trim() || this.isLoading ? "default" : "pointer"
    this.sendBtnEl.style.background =
      !val.trim() || this.isLoading ? "rgba(255,255,255,0.06)" : "linear-gradient(135deg, #10b981, #059669)"

    // Auto-resize textarea height
    this.inputEl.style.height = "auto"
    this.inputEl.style.height = Math.min(this.inputEl.scrollHeight, 100) + "px"
    // Toggle icon stroke
    const svg = this.sendBtnEl.querySelector("svg")
    if (svg) {
      svg.style.stroke = !val.trim() || this.isLoading ? "rgba(255,255,255,0.25)" : "#022c22"
    }
  }

  onKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      this.sendMessage()
    }
  }

  showLoader() {
    this.isLoading = true
    if (this.loaderEl) this.loaderEl.style.display = "block"
  }

  hideLoader() {
    this.isLoading = false
    if (this.loaderEl) this.loaderEl.style.display = "none"
    this.sendBtnEl.disabled = !(this.inputEl.value || "").trim()
  }

  renderSuggestedPromptsIfNeeded() {
    if (!this.suggestedEl) return
    if (this.messages.length !== 1) return

    this.suggestedEl.innerHTML = `
      <div style="font-size: 11px; color: rgba(255,255,255,0.3); text-transform: uppercase; letter-spacing: 0.08em; font-weight: 600; margin-bottom: 2px; padding-left: 0px;">Try asking</div>
    `

    const prompts = [
      "We're a clinic with 3,000+ patient calls/month — where can AI help?",
      "I run a SaaS platform and want to add AI features",
      "Our team spends 20+ hrs/week on manual data entry",
      "How do you typically approach an AI project?",
    ]

    prompts.forEach((p) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.textContent = p
      btn.style.cssText = `
        background: rgba(255,255,255,0.04);
        border: 1px solid rgba(255,255,255,0.1);
        border-radius: 12px;
        padding: 11px 16px;
        color: rgba(255,255,255,0.65);
        font-size: 13px;
        text-align: left;
        cursor: pointer;
        transition: all 0.2s;
        font-family: inherit;
      `
      btn.addEventListener("click", () => this.sendMessage(p))
      this.suggestedEl.appendChild(btn)
    })
  }

  maybeShowLeadForm() {
    // Disabled for now (per request).
    return
    if (this.showLeadForm || this.leadSubmitted) return
    if (this.messageCount < 2) return

    if (this.pendingLeadTimer) clearTimeout(this.pendingLeadTimer)
    this.pendingLeadTimer = setTimeout(() => {
      this.showLeadForm = true
      this.renderLeadForm()
    }, 1500)
  }

  renderLeadForm() {
    if (!this.leadMountEl) return
    this.leadMountEl.style.display = "block"

    this.leadMountEl.innerHTML = `
      <div style="background: linear-gradient(135deg, #0a2a1f 0%, #0d3327 100%); border: 1px solid #1a4a38; border-radius: 16px; padding: 20px 22px; display: flex; flex-direction: column; gap: 10;">
        <div style="font-size: 14px; color: #6ee7b7; font-weight: 700; margin-bottom: 2px;">Leave your info — Ahmad will follow up personally</div>
        <div style="display:flex; flex-direction:column; gap: 10;">
          <input id="astw-lead-name" placeholder="Your name *" style="${this.leadInputStyle("name")}"/>
          <div id="astw-lead-name-err" style="color:#f87171;font-size:12px;margin-top:-6px;display:none;"></div>
          <input id="astw-lead-email" placeholder="Email *" style="${this.leadInputStyle("email")}"/>
          <div id="astw-lead-email-err" style="color:#f87171;font-size:12px;margin-top:-6px;display:none;"></div>
          <input id="astw-lead-company" placeholder="Company / Business name *" style="${this.leadInputStyle("company")}"/>
          <div id="astw-lead-company-err" style="color:#f87171;font-size:12px;margin-top:-6px;display:none;"></div>
          <input id="astw-lead-phone" placeholder="Phone (optional)" style="${this.leadInputStyle("phone")}"/>
          <button id="astw-lead-submit" type="button" style="margin-top:4px; padding: 12px 20px; background: linear-gradient(135deg, #10b981, #059669); color:#022c22; border:none; border-radius: 10px; font-size: 14px; font-weight: 700; cursor:pointer; letterSpacing:0.02em;">Send → Ahmad will reach out within 24hrs</button>
        </div>
      </div>
    `

    const nameEl = this.leadMountEl.querySelector("#astw-lead-name")
    const emailEl = this.leadMountEl.querySelector("#astw-lead-email")
    const companyEl = this.leadMountEl.querySelector("#astw-lead-company")
    const phoneEl = this.leadMountEl.querySelector("#astw-lead-phone")
    const submitBtn = this.leadMountEl.querySelector("#astw-lead-submit")

    submitBtn.addEventListener("click", async () => {
      const payload = {
        name: nameEl.value,
        email: emailEl.value,
        company: companyEl.value,
        phone: phoneEl.value,
      }
      const validation = this.validateLead(payload)
      this.clearLeadErrors()

      if (!validation.ok) {
        this.showLeadError("name", validation.errors.name)
        this.showLeadError("email", validation.errors.email)
        this.showLeadError("company", validation.errors.company)
        return
      }

      submitBtn.disabled = true
      submitBtn.style.opacity = 0.8

      try {
        const response = await fetch("/chat/lead_new", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          },
          body: JSON.stringify({
            lead: payload,
            history: this.getApiHistory(),
          }),
        })

        const data = await response.json()
        if (!response.ok || data.error) throw new Error(data.error || "Lead submission failed")

        this.leadSubmitted = true
        this.showLeadForm = false
        this.leadMountEl.innerHTML = ""
        this.leadMountEl.style.display = "none"

        this.appendMessageBubble({ role: "assistant", content: data.message })
      } catch (err) {
        // Keep the form open; show a generic error
        this.showLeadError("company", "Could not submit. Please try again.")
        submitBtn.disabled = false
        submitBtn.style.opacity = 1
      }
    })
  }

  leadInputStyle(field) {
    return `width: 100%; padding: 11px 14px; background: #0a2a1f; border: 1px solid #1a4a38; border-radius: 10px; color: #e2e8f0; font-size: 14px; outline: none; font-family: inherit; box-sizing: border-box; transition: border-color 0.2s;`
  }

  validateLead({ name, email, company }) {
    const errors = {}
    if (!name || !name.trim()) errors.name = "Name is required"
    if (!email || !/\\S+@\\S+\\.\\S+/.test(email)) errors.email = "Valid email required"
    if (!company || !company.trim()) errors.company = "Company name is required"
    return { ok: Object.keys(errors).length === 0, errors }
  }

  clearLeadErrors() {
    ["name", "email", "company"].forEach((f) => {
      const el = this.leadMountEl.querySelector(`#astw-lead-${f}-err`)
      if (el) {
        el.style.display = "none"
        el.textContent = ""
      }
    })
  }

  showLeadError(field, message) {
    const el = this.leadMountEl.querySelector(`#astw-lead-${field}-err`)
    if (!el) return
    if (!message) return
    el.textContent = message
    el.style.display = "block"
  }

  getApiHistory() {
    // Keep only user/assistant and last 10 messages to bound token usage.
    const filtered = this.messages
      .filter((m) => m.role === "user" || m.role === "assistant")
      .map((m) => ({ role: m.role, content: m.content }))

    return filtered.length > 5 ? filtered.slice(filtered.length - 5) : filtered
  }

  async sendMessage(textOverride) {
    const rawText = typeof textOverride === "string" ? textOverride : this.inputEl.value
    const text = (rawText || "").trim()
    if (!text || this.isLoading) return

    // Gate only until the first successful verification in this page session.
    if (this.recaptchaEnabled && !this.recaptchaVerifiedOnce) {
      this.showRecaptchaError("Please complete reCAPTCHA to start the chat.")
      this.showRecaptchaWrap(true)
      return
    }

    this.isLoading = true
    this.inputEl.value = ""
    this.onInputChange()

    // Add user message
    const userMsg = { role: "user", content: text }
    this.messages.push(userMsg)
    const userWrapper = this.appendMessageBubble(userMsg)

    this.isLoading = true
    this.loaderEl.style.display = "block"
    this.scrollElementIntoView(this.loaderEl)

    const history = this.getApiHistory()

    // Increment message count (used to decide when to show lead form).
    this.messageCount += 1

    try {
      const recaptchaToken = this.getRecaptchaToken()
      const response = await fetch("/chat/message_new", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
        body: JSON.stringify({
          message: text,
          history: history,
          recaptcha_token: recaptchaToken,
        }),
      })

      const data = await response.json()
      if (!response.ok || data.error) throw new Error(data.error || "AI request failed")

      const assistantMsg = {
        role: "assistant",
        content: data.message,
        meta: {
          citations: data.citations,
          suggestions: data.suggestions,
          answer_style: data.answer_style,
          confidence: data.confidence,
        },
      }
      this.messages.push(assistantMsg)
      this.appendMessageBubble(assistantMsg)
      // If the assistant response is long, don't yank the user to the bottom.
      // Keep the viewport anchored at the user's question.
      this.scrollElementIntoView(userWrapper, { block: "start" })

      this.maybeShowLeadForm()

      // After the first successful message, never show/require reCAPTCHA again this session.
      this.hasSentFirstMessage = true
      this.showRecaptchaWrap(false)
    } catch (_err) {
      const assistantMsg = {
        role: "assistant",
        content:
          "Looks like I'm having a connection issue. No worries — you can reach Ahmad directly at **ahmad@astechware.com** or [book a 30-min call here](https://calendly.com/ahmadkamran/new-meeting).",
      }
      this.messages.push(assistantMsg)
      this.appendMessageBubble(assistantMsg)
      this.scrollElementIntoView(userWrapper, { block: "start" })
    } finally {
      this.loaderEl.style.display = "none"
      this.isLoading = false
      this.onInputChange()
      this.inputEl.focus()
    }
  }

  initRecaptchaIfNeeded() {
    if (!this.recaptchaEnabled) return

    // Require only before the first message; if server session already passed, we can skip later.
    // We don't know server state here, so we gate until user verifies once in the browser.
    this.showRecaptchaWrap(true)

    const tryRender = () => {
      const container = this.element.querySelector("#astw-recaptcha")
      if (!container) return false
      if (!window.grecaptcha || typeof window.grecaptcha.render !== "function") return false

      // Avoid rendering multiple times
      if (this.recaptchaWidgetId !== null) return true

      this.recaptchaWidgetId = window.grecaptcha.render(container, {
        sitekey: this.recaptchaSiteKeyValue,
        callback: () => {
          this.recaptchaVerified = true
          this.recaptchaVerifiedOnce = true
          this.hideRecaptchaError()
          this.showRecaptchaWrap(false)
          this.onInputChange()
        },
        "expired-callback": () => {
          // If the user already verified once, never bother them again.
          if (this.recaptchaVerifiedOnce) return
          this.recaptchaVerified = false
          this.showRecaptchaWrap(true)
          this.onInputChange()
        },
        "error-callback": () => {
          // If the user already verified once, ignore errors/expiry noise.
          if (this.recaptchaVerifiedOnce) return
          this.recaptchaVerified = false
          this.showRecaptchaError("reCAPTCHA error. Please try again.")
          this.showRecaptchaWrap(true)
          this.onInputChange()
        },
      })
      return true
    }

    // Try immediately, otherwise poll briefly until the script loads.
    if (tryRender()) return
    let attempts = 0
    const timer = setInterval(() => {
      attempts += 1
      if (tryRender() || attempts > 30) clearInterval(timer)
    }, 250)
  }

  getRecaptchaToken() {
    if (!this.recaptchaEnabled) return null
    if (this.recaptchaWidgetId === null) return null
    if (!window.grecaptcha || typeof window.grecaptcha.getResponse !== "function") return null
    return window.grecaptcha.getResponse(this.recaptchaWidgetId)
  }

  showRecaptchaWrap(show) {
    const wrap = this.element.querySelector("#astw-recaptcha-wrap")
    if (!wrap) return
    wrap.style.display = show ? "block" : "none"
  }

  showRecaptchaError(msg) {
    const el = this.element.querySelector("#astw-recaptcha-error")
    if (!el) return
    el.textContent = msg
    el.style.display = "block"
  }

  hideRecaptchaError() {
    const el = this.element.querySelector("#astw-recaptcha-error")
    if (!el) return
    el.textContent = ""
    el.style.display = "none"
  }

  disconnect() {
    if (this.pendingLeadTimer) {
      clearTimeout(this.pendingLeadTimer)
      this.pendingLeadTimer = null
    }
  }
}

