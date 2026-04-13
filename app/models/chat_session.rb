# frozen_string_literal: true

class ChatSession < ApplicationRecord
  has_many :chat_messages, dependent: :destroy

  validates :visitor_id, presence: true, uniqueness: true
  validates :status, presence: true
end

