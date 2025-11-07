# frozen_string_literal: true

module Products
  class ReviewsController < ApplicationController
    before_action :require_login!
    before_action :set_product
    before_action :set_review, only: :destroy

    def create
      @review = current_user.reviews.find_or_initialize_by(product: @product)
      @review.assign_attributes(review_params)

      if @review.save
        flash[:success] = "Thank you for reviewing this product!"
        redirect_to product_path(@product)
      else
        @reviews = @product.visible_reviews.includes(:user).recent_first
        @user_review = @review
        @wishlist_item_present = current_user&.wishlisted_product?(@product)
        flash.now[:error] = @review.errors.full_messages.to_sentence
        render "products/show", status: :unprocessable_entity
      end
    end

    def destroy
      @review.destroy!
      flash[:success] = "Your review has been removed."
      redirect_to product_path(@product), status: :see_other
    end

    private

    def set_product
      @product = Product.find_by_slug_or_id!(params[:product_id])
    end

    def set_review
      @review = current_user.reviews.find_by!(product: @product)
    end

    def review_params
      params.require(:review).permit(:rating, :comment)
    end
  end
end
