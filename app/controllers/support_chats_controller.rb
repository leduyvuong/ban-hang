# frozen_string_literal: true

class SupportChatsController < ApplicationController
  before_action :require_login!
  before_action :ensure_customer!

  def show
    @support_agent = support_agent!
    @conversation = Conversation.find_or_create_between(current_user, @support_agent)
    @conversation.mark_as_read!(current_user)
    @messages = @conversation.messages.includes(:user).order(created_at: :desc).limit(50).reverse
    @message = @conversation.messages.build

    broadcast_new_conversation_if_needed
  end

  private

  def ensure_customer!
    redirect_to admin_messages_path if admin?
  end

  def support_agent!
    Conversation.support_agent || raise(ActiveRecord::RecordNotFound, "Support agent not configured")
  end

  def broadcast_new_conversation_if_needed
    return unless @conversation.previous_changes.key?("id")

    Turbo::StreamsChannel.broadcast_append_to(
      [@support_agent, :admin_conversations],
      target: "admin_conversation_list",
      partial: "admin/messages/conversation",
      locals: { conversation: @conversation, viewer: @support_agent }
    )
  end
end
