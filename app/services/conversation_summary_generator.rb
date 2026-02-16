# frozen_string_literal: true

class ConversationSummaryGenerator
  def self.generate(conversation_history:, current_message:)
    new(conversation_history: conversation_history, current_message: current_message).generate
  end

  def initialize(conversation_history:, current_message:)
    @conversation_history = conversation_history || []
    @current_message = current_message
  end

  def generate
    api_key = ENV['OPENAI_API_KEY']
    model = ENV['OPENAI_MODEL'] || 'gpt-4o-mini'

    if api_key.blank?
      Rails.logger.error 'OpenAI API key not configured for conversation summary'
      return fallback_summary
    end

    begin
      client = OpenAI::Client.new(access_token: api_key)

      # Build messages for summary generation
      messages = [
        {
          role: 'system',
          content: summary_prompt
        }
      ]

      # Add conversation history
      @conversation_history.each do |msg|
        messages << { role: msg['role'], content: msg['content'] }
      end

      # Add current message
      messages << { role: 'user', content: @current_message }

      response = client.chat(
        parameters: {
          model: model,
          messages: messages,
          temperature: 0.5,
          max_tokens: 300
        }
      )

      summary = response.dig('choices', 0, 'message', 'content')
      
      if summary.blank?
        return fallback_summary
      end

      summary.strip
    rescue StandardError => e
      Rails.logger.error "Conversation Summary Generation Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      fallback_summary
    end
  end

  private

  def summary_prompt
    <<~PROMPT
      You are summarizing a customer support conversation for a business owner. Create a clear, concise summary that helps them understand:
      1. What the customer was asking about
      2. What information was provided
      3. What the customer's needs/goals are

      Write the summary in 2-3 short paragraphs. Be specific and focus on actionable information.
      Do not include greetings or pleasantries - just the key facts and context.

      Format the summary professionally, as if you're briefing a colleague about the conversation.
    PROMPT
  end

  def fallback_summary
    # Fallback to a simple summary if GPT fails
    summary_parts = []
    @conversation_history.last(3).each do |msg|
      if msg['role'] == 'user'
        summary_parts << "Customer asked: #{msg['content'][0..150]}"
      end
    end
    summary_parts << "Latest message: #{@current_message[0..200]}"
    summary_parts.join("\n\n")
  end
end
