# frozen_string_literal: true

class CreateChatMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_messages, id: :uuid do |t|
      t.references :chat_session, null: false, foreign_key: true, index: true

      # user | assistant | system
      t.string :role, null: false
      t.text :content, null: false

      # Tracking / analytics
      t.string :provider # e.g. "pipeline", "openai"
      t.string :model
      t.string :request_id
      t.integer :latency_ms

      # Full structured payload (citations, suggestions, confidence, flags, etc.)
      t.jsonb :meta, null: false, default: {}

      t.timestamps
    end

    add_index :chat_messages, %i[chat_session_id created_at]
    add_index :chat_messages, :role
    add_index :chat_messages, :provider
  end
end