# frozen_string_literal: true

module Admin
  class MessagesController < ApplicationController
    before_action :set_support_agent

    def index
      set_admin_page(title: "Messages", subtitle: "Chat with customers in real time")
      @query = params[:query].to_s.strip
      @conversations = load_conversations
      @selected_conversation = find_conversation

      if @selected_conversation
        @messages = @selected_conversation.messages.includes(:user).order(created_at: :desc).limit(50).reverse
        @new_message = @selected_conversation.messages.build
        @selected_conversation.mark_as_read!(@support_agent)
      end
    end

    def mark_all_read
      @support_agent = support_agent!
      @support_agent.conversation_participants.update_all(last_read_at: Time.current)

      @support_agent.conversations.includes(:latest_message, conversation_participants: :user).find_each do |conversation|
        Turbo::StreamsChannel.broadcast_replace_to(
          [@support_agent, :admin_conversations],
          target: "admin_conversation_#{conversation.id}",
          partial: "admin/messages/conversation",
          locals: { conversation: conversation, viewer: @support_agent }
        )
      end

      respond_to do |format|
        format.html do
          redirect_to admin_messages_path, notice: "All conversations marked as read."
        end
        format.turbo_stream do
          redirect_to admin_messages_path, notice: "All conversations marked as read."
        end
      end
    end

    private

    def set_support_agent
      @support_agent = support_agent!
    end

    def support_agent!
      Conversation.support_agent || raise(ActiveRecord::RecordNotFound, "Support agent not configured")
    end

    def load_conversations
      conversations = @support_agent.conversations
                                     .includes(:latest_message, conversation_participants: :user)
                                     .ordered_by_activity

      return conversations.to_a if @query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      conversations
        .joins(:participants)
        .where.not(conversation_participants: { user_id: @support_agent.id })
        .where("users.name ILIKE :pattern OR users.email ILIKE :pattern", pattern: pattern)
        .distinct
        .to_a
    end

    def find_conversation
      return nil if @conversations.empty?

      if params[:conversation_id].present?
        @conversations.find { |conversation| conversation.id == params[:conversation_id].to_i }
      else
        @conversations.first
      end
    end
  end
end
