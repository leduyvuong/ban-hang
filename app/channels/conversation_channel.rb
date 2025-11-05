# frozen_string_literal: true

class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = current_user.conversations.find_by(id: params[:id])

    if conversation
      stream_for conversation
      stream_for [conversation, :sidebar]
    else
      reject
    end
  end
end
