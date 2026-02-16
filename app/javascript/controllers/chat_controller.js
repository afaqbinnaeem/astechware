import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bubble", "window", "messages", "input", "sendButton"]

  connect() {
    this.isMinimized = true
    this.updateVisibility()
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.isMinimized = !this.isMinimized
    this.updateVisibility()
  }

  updateVisibility() {
    if (this.isMinimized) {
      this.bubbleTarget.style.display = "flex"
      this.windowTarget.style.display = "none"
    } else {
      this.bubbleTarget.style.display = "none"
      this.windowTarget.style.display = "flex"
      // Focus input when opening
      setTimeout(() => {
        if (this.hasInputTarget) {
          this.inputTarget.focus()
        }
      }, 100)
    }
  }

  async sendMessage(event) {
    event.preventDefault()
    
    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to chat
    this.addMessage(message, "user")
    this.inputTarget.value = ""
    this.inputTarget.disabled = true
    this.sendButtonTarget.disabled = true

    // Show loader
    this.showLoader()

    try {
      const response = await fetch("/chat/message", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ message: message })
      })

      const data = await response.json()

      if (data.error) {
        this.addMessage(data.error, "error")
      } else {
        this.addMessage(data.message, "ai")
      }
    } catch (error) {
      this.addMessage("Sorry, I'm having trouble connecting. Please try again later.", "error")
    } finally {
      this.hideLoader()
      this.inputTarget.disabled = false
      this.sendButtonTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  addMessage(text, type) {
    const messageDiv = document.createElement("div")
    messageDiv.className = `chat-message chat-message-${type}`
    
    const messageContent = document.createElement("div")
    messageContent.className = "chat-message-content"
    messageContent.textContent = text
    
    messageDiv.appendChild(messageContent)
    this.messagesTarget.appendChild(messageDiv)
    
    // Scroll to bottom
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  showLoader() {
    const loaderDiv = document.createElement("div")
    loaderDiv.className = "chat-message chat-message-ai chat-message-loading"
    loaderDiv.id = "chat-loader"
    
    const loaderContent = document.createElement("div")
    loaderContent.className = "chat-message-content"
    loaderContent.innerHTML = '<span class="thinking-dots"><span>.</span><span>.</span><span>.</span></span> Thinking...'
    
    loaderDiv.appendChild(loaderContent)
    this.messagesTarget.appendChild(loaderDiv)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  hideLoader() {
    const loader = document.getElementById("chat-loader")
    if (loader) {
      loader.remove()
    }
  }

  handleKeyPress(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage(event)
    }
  }
}
