import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bubble", "window", "messages", "input", "sendButton"]

  connect() {
    this.isMinimized = false
    this.updateVisibility()
    // Clear sessionStorage on page load/reload
    this.clearHistory()
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
      // Check and clear history when chat is opened if messages are empty
      this.checkAndClearIfEmpty()
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

    // Load conversation history
    const history = this.loadHistory()

    // Show loader
    this.showLoader()

    try {
      const response = await fetch("/chat/message", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ 
          message: message,
          history: history
        })
      })

      const data = await response.json()

      if (data.error) {
        this.addMessage(data.error, "error")
      } else {
        this.addMessage(data.message, "ai")
        // Save both user message and AI response to history
        this.saveToHistory(message, data.message)
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

  // Conversation history management
  loadHistory() {
    try {
      const historyJson = sessionStorage.getItem('chat_history')
      if (historyJson) {
        const history = JSON.parse(historyJson)
        // Ensure it's an array and has valid format
        if (Array.isArray(history)) {
          return history.filter(msg => 
            msg && 
            typeof msg === 'object' && 
            msg.role && 
            msg.content &&
            (msg.role === 'user' || msg.role === 'assistant')
          )
        }
      }
    } catch (error) {
      console.error('Error loading chat history:', error)
    }
    return []
  }

  saveToHistory(userMessage, aiMessage) {
    try {
      const history = this.loadHistory()
      
      // Add user message
      history.push({ role: 'user', content: userMessage })
      
      // Add AI response
      history.push({ role: 'assistant', content: aiMessage })
      
      // Keep only last 10 messages
      if (history.length > 10) {
        history.splice(0, history.length - 10)
      }
      
      // Save back to sessionStorage
      sessionStorage.setItem('chat_history', JSON.stringify(history))
    } catch (error) {
      console.error('Error saving chat history:', error)
    }
  }

  clearHistory() {
    try {
      sessionStorage.removeItem('chat_history')
    } catch (error) {
      console.error('Error clearing chat history:', error)
    }
  }

  // Check if messages container only has the welcome message and clear history if so
  checkAndClearIfEmpty() {
    try {
      // Get all message elements (excluding the loader)
      const messageElements = this.messagesTarget.querySelectorAll('.chat-message:not(#chat-loader)')
      
      // If only welcome message exists (no user/AI messages), clear history
      // This handles cases where messages were cleared or page was reset
      if (messageElements.length <= 1) {
        this.clearHistory()
      }
    } catch (error) {
      console.error('Error checking messages:', error)
    }
  }
}
