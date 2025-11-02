# frozen_string_literal: true

class NewsletterSubscriptionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create, if: -> { request.format.turbo_stream? }
  skip_before_action :require_login!, only: :create

  def create
    @newsletter_subscription = NewsletterSubscription.new(newsletter_params)

    respond_to do |format|
      if @newsletter_subscription.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "newsletter_form",
            partial: "pages/newsletter/success"
          )
        end
        format.html { redirect_to root_path, notice: "Thank you for subscribing!" }
        format.json { render json: { success: true }, status: :created }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "newsletter_form",
            partial: "pages/newsletter/form",
            locals: { newsletter_subscription: @newsletter_subscription }
          )
        end
        format.html do
          flash[:error] = @newsletter_subscription.errors.full_messages.to_sentence
          redirect_to root_path
        end
        format.json { render json: { success: false, error: @newsletter_subscription.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  private

  def newsletter_params
    params.require(:newsletter_subscription).permit(:email)
  end
end
