# frozen_string_literal: true

class ContactInfoExtractor
  def self.extract(conversation_history:, current_message:)
    new(conversation_history: conversation_history, current_message: current_message).extract
  end

  def initialize(conversation_history:, current_message:)
    @conversation_history = conversation_history || []
    @current_message = current_message
  end

  def extract
    api_key = ENV['OPENAI_API_KEY']
    model = ENV['OPENAI_MODEL'] || 'gpt-4o-mini'

    if api_key.blank?
      Rails.logger.error 'OpenAI API key not configured for contact info extraction'
      return default_response
    end

    begin
      client = OpenAI::Client.new(access_token: api_key)

      # Build messages for extraction
      messages = [
        {
          role: 'system',
          content: extraction_prompt
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
        temperature: 0.2, # Low temperature for accurate extraction
        max_tokens: 300
      }

      # Only use JSON mode if model supports it
      if model.include?('gpt-4') || model.include?('gpt-3.5')
        parameters[:response_format] = { type: 'json_object' }
      end

      response = client.chat(parameters: parameters)

      content = response.dig('choices', 0, 'message', 'content')
      return default_response if content.blank?

      # Try to parse as JSON
      result = JSON.parse(content)
      
      {
        name: result['name']&.strip,
        email: result['email']&.strip&.downcase,
        company_name: result['company_name']&.strip,
        description: result['description']&.strip
      }
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error in Contact Extraction: #{e.message}"
      Rails.logger.error "Response content: #{content}"
      default_response
    rescue StandardError => e
      Rails.logger.error "Contact Info Extraction Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      default_response
    end
  end

  private

  def extraction_prompt
    <<~PROMPT
      You are a contact information extractor. Extract structured contact information from the conversation.

      Return a JSON object with this exact structure:
      {
        "name": "extracted name or null",
        "email": "extracted email address or null",
        "company_name": "extracted company name or null",
        "description": "extracted description/query or null"
      }

      Extract the following information from the conversation:
      - name: The user's full name (first and last name if available)
      - email: A valid email address
      - company_name: Company or organization name (optional, can be null)
      - description: The user's query, question, or description of what they're looking for

      Rules:
      - If a field cannot be found, set it to null
      - Email must be a valid email format
      - Name should be the person's actual name, not a username or handle
      - Description should capture what the user wants to accomplish or their question
      - Look through the entire conversation history, not just the last message
      - If information appears in multiple messages, use the most recent or complete version

      Return only valid JSON, no additional text.
    PROMPT
  end

  def default_response
    { name: nil, email: nil, company_name: nil, description: nil }
  end
end
