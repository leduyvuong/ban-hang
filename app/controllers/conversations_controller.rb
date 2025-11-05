# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :require_login!
  before_action :set_conversation, only: :show

  def index
    @conversations = load_conversations
  end

  def show
    @conversations = load_conversations
    @messages = @conversation.messages.includes(:user).order(created_at: :desc).limit(50).reverse
    @message = @conversation.messages.build
    @conversation.mark_as_read!(current_user)
  end

  def create
    other_user = User.find(conversation_params[:user_id])

    if other_user == current_user
      flash[:error] = "You cannot start a conversation with yourself."
      return redirect_to conversations_path
    end

    conversation = Conversation.between(current_user, other_user)

    unless conversation
      conversation = Conversation.create!
      conversation.conversation_participants.create!(user: current_user, last_read_at: Time.current)
      conversation.conversation_participants.create!(user: other_user)
    end

    conversation.mark_as_read!(current_user)

    redirect_to conversation_path(conversation)
  rescue ActiveRecord::RecordNotFound
    respond_with_error("We couldn't find that user.", status: :not_found, redirect: conversations_path)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_error(e.record.errors.full_messages.to_sentence, status: :unprocessable_entity, redirect: conversations_path)
  rescue ActionController::ParameterMissing
    respond_with_error("Please choose a user to start a conversation.", status: :unprocessable_entity, redirect: conversations_path)
  end

  private

  def load_conversations
    current_user.conversations
                .includes(:latest_message, conversation_participants: :user)
                .ordered_by_activity
  end

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:user_id)
  end
end
