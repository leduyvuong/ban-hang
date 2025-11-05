# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :content, presence: true, length: { maximum: 5000 }

  before_validation :sanitize_content

  after_create_commit :notify_participants

  scope :recent, -> { order(created_at: :desc) }

  private

  def sanitize_content
    sanitized = ActionView::Base.full_sanitizer.sanitize(content.to_s)
    self.content = sanitized.strip
  end

  def notify_participants
    conversation.mark_as_read!(user)
    is_first_message = conversation.messages.count == 1

    conversation.participants.find_each do |participant|
      # Broadcast message to conversation view
      broadcast_append_to(
        [participant, conversation],
        target: "messages_conversation_#{conversation_id}",
        partial: "messages/message",
        locals: { message: self, viewer: participant }
      )

      # Update conversation in sidebar
      broadcast_replace_to(
        [participant, :conversations],
        target: "conversation_#{conversation_id}",
        partial: "conversations/conversation",
        locals: { conversation: conversation, current_user: participant }
      )

      if participant.admin?
        # If this is first message in a new conversation, append it to the list
        if is_first_message
          broadcast_append_to(
            [participant, :admin_conversations],
            target: "admin_conversation_list",
            partial: "admin/messages/conversation",
            locals: { conversation: conversation, viewer: participant }
          )
          
          # Also broadcast subscription for the new conversation
          broadcast_action_to(
            [participant, :admin_conversations],
            action: :append,
            target: "admin_subscriptions",
            html: turbo_stream_from_tag([participant, conversation])
          )
        else
          # Update existing conversation in admin sidebar
          broadcast_replace_to(
            [participant, :admin_conversations],
            target: "admin_conversation_#{conversation_id}",
            partial: "admin/messages/conversation",
            locals: { conversation: conversation, viewer: participant }
          )
        end
      else
        broadcast_replace_to(
          [participant, :support_chat],
          target: "chat_widget_toggle",
          partial: "shared/chat_widget_toggle",
          locals: { conversation: conversation, viewer: participant }
        )
      end
    end
  end

  def turbo_stream_from_tag(streamable)
    "<turbo-cable-stream-source channel=\"Turbo::StreamsChannel\" signed-stream-name=\"#{Turbo::StreamsChannel.signed_stream_name(streamable)}\"></turbo-cable-stream-source>".html_safe
  end
end
