# frozen_string_literal: true

class Conversation < ApplicationRecord
  SUPPORT_EMAIL = "admin@banhang.test"

  has_many :conversation_participants, dependent: :destroy, inverse_of: :conversation
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy, inverse_of: :conversation
  has_one :latest_message, -> { order(created_at: :desc) }, class_name: "Message", inverse_of: :conversation

  scope :ordered_by_activity, -> { order(updated_at: :desc) }

  def self.between(user_a, user_b)
    user_ids = [user_a.id, user_b.id].sort

    joins(:conversation_participants)
      .where(conversation_participants: { user_id: user_ids })
      .group(:id)
      .having("COUNT(DISTINCT conversation_participants.user_id) = ?", user_ids.size)
      .first
  end

  def self.find_or_create_between(user_a, user_b)
    transaction do
      conversation = between(user_a, user_b)
      return conversation if conversation

      conversation = create!
      conversation.conversation_participants.create!(user: user_a)
      conversation.conversation_participants.create!(user: user_b)
      conversation
    end
  end

  def self.support_agent
    User.find_by(email: SUPPORT_EMAIL)
  end

  def self.support_conversation_for(user)
    agent = support_agent
    return unless agent

    between(user, agent)
  end

  def unread_count_for(user)
    participant = conversation_participants.find { |cp| cp.user_id == user.id } || conversation_participants.find_by(user: user)
    return 0 if participant.blank?

    cutoff = participant.last_read_at || Time.at(0)
    messages.where("messages.created_at > ?", cutoff).where.not(user_id: user.id).count
  end

  def last_message
    latest_message || messages.order(created_at: :desc).first
  end

  def mark_as_read!(user)
    participant = conversation_participants.find_by(user: user)
    return unless participant

    participant.touch(:last_read_at)
  end

  def other_participant(current_user)
    participants.detect { |participant| participant != current_user }
  end
end
