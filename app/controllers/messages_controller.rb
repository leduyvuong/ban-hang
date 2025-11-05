# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :require_login!
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params.merge(user: current_user))

    respond_to do |format|
      if @message.save
        format.turbo_stream { head :ok }
        format.html { redirect_to conversation_path(@conversation) }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_message_form",
            partial: "messages/form",
            locals: { conversation: @conversation, message: @message }
          )
        end

        format.html do
          flash[:error] = @message.errors.full_messages.to_sentence
          redirect_to conversation_path(@conversation)
        end
      end
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
