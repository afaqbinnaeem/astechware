class CreateChatSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_sessions do |t|
      t.string :visitor_id, null: false

      t.datetime :last_message_at
      t.string :status, null: false, default: "open"

      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :chat_sessions, :visitor_id, unique: true
    add_index :chat_sessions, :last_message_at
  end
end
