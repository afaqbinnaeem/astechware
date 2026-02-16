# frozen_string_literal: true

class ChatIntentClassifier
  def self.classify(conversation_history:, current_message:)
    new(conversation_history: conversation_history, current_message: current_message).classify
  end

  def initialize(conversation_history:, current_message:)
    @conversation_history = conversation_history || []
    @current_message = current_message
  end

  def classify
    api_key = ENV['OPENAI_API_KEY']
    model = ENV['OPENAI_CLASSIFICATION_MODEL'] || ENV['OPENAI_MODEL'] || 'gpt-4o-mini'

    if api_key.blank?
      Rails.logger.error 'OpenAI API key not configured for intent classification'
      return default_response
    end

    begin
      client = OpenAI::Client.new(access_token: api_key)

      # Build messages for classification
      messages = [
        {
          role: 'system',
          content: classification_prompt
        }
      ]

      # Add conversation history
      @conversation_history.each do |msg|
        messages << { role: msg['role'], content: msg['content'] }
      end

      # Add current message
      messages << { role: 'user', content: @current_message }

      parameters = {
        model: model,
        messages: messages,
        temperature: 0.3, # Lower temperature for more consistent classification
        max_tokens: 200
      }

      # Only use JSON mode if model supports it (gpt-4o, gpt-4-turbo, etc.)
      # For older models, we'll parse the text response
      if model.include?('gpt-4') || model.include?('gpt-3.5')
        parameters[:response_format] = { type: 'json_object' }
      end

      response = client.chat(parameters: parameters)

      content = response.dig('choices', 0, 'message', 'content')
      return default_response if content.blank?

      # Try to parse as JSON
      result = JSON.parse(content)
      
      intent = result['intent']&.downcase
      intent = 'simple_chat' unless %w[simple_chat sending_information].include?(intent)
      
      {
        intent: intent,
        confidence: result['confidence'] || 'medium'
      }
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error in Intent Classification: #{e.message}"
      Rails.logger.error "Response content: #{content}"
      # Try to extract intent from text response as fallback
      extract_intent_from_text(content)
    rescue StandardError => e
      Rails.logger.error "Intent Classification Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      default_response
    end
  end

  private

  def classification_prompt
    <<~PROMPT
      You are an intent classifier for a customer support chat widget. Your job is to determine if the user is providing their contact information (name, email, description/query) or just having a regular conversation.

      Analyze the conversation history and the current user message to determine the intent.

      Return a JSON object with this exact structure:
      {
        "intent": "simple_chat" or "sending_information",
        "confidence": "high" or "medium" or "low"
      }

      Classify as "sending_information" when:
      - The user provides their name AND email address in the current message or recent conversation
      - The user is responding to a request for contact information
      - The message contains contact details along with a description of what they're looking for
      - The conversation context suggests the user is providing information to be contacted

      Classify as "simple_chat" when:
      - The user is asking questions or having a conversation
      - No contact information (name + email) is present
      - The user is just seeking information without providing their details

      Be strict: Only classify as "sending_information" if you can clearly identify both a name and an email address in the conversation.

      Return only valid JSON, no additional text.
    PROMPT
  end

  def default_response
    { intent: 'simple_chat', confidence: 'low' }
  end

  def extract_intent_from_text(text)
    # Fallback: try to extract intent from text response
    text_lower = text.downcase
    if text_lower.include?('sending_information') || text_lower.include?('providing information')
      { intent: 'sending_information', confidence: 'low' }
    else
      { intent: 'simple_chat', confidence: 'low' }
    end
  end
end
