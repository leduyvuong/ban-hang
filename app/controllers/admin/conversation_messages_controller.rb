# frozen_string_literal: true

module Admin
  class ConversationMessagesController < ApplicationController
    before_action :set_support_agent
    before_action :set_conversation

    def create
      @message = @conversation.messages.build(message_params.merge(user: @support_agent))

      respond_to do |format|
        if @message.save
          format.turbo_stream { head :ok }
          format.html { redirect_to admin_messages_path(conversation_id: @conversation.id) }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "admin_new_message_form",
              partial: "admin/messages/form",
              locals: { conversation: @conversation, message: @message }
            )
          end

          format.html do
            flash[:error] = @message.errors.full_messages.to_sentence
            redirect_to admin_messages_path(conversation_id: @conversation.id)
          end
        end
      end
    end

    private

    def set_support_agent
      @support_agent = Conversation.support_agent || raise(ActiveRecord::RecordNotFound, "Support agent not configured")
    end

    def set_conversation
      @conversation = @support_agent.conversations.find(params[:conversation_id])
    end

    def message_params
      params.require(:message).permit(:content)
    end
  end
end
