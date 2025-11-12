# frozen_string_literal: true

class ReviewsController < ApplicationController
  include Pagy::Backend

  def show
    reviews_scope = Review
                    .includes(:user, :product)
                    .where(user_id: current_user.id)
                    .order(created_at: :desc)

    @pagy, @reviews = pagy(reviews_scope, items: 20)

    set_page_metadata(
      title: "Customer Reviews",
      description: "Read what our customers are saying about our products and services."
    )
  end
end
