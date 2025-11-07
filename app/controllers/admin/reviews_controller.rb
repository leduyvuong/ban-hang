# frozen_string_literal: true

module Admin
  class ReviewsController < ApplicationController
    before_action :set_review, only: %i[update destroy]

    def index
      @query = params[:query].to_s.strip
      @status_filter = params[:status].presence

      scope = Review.includes(:product, :user).order(created_at: :desc)
      scope = scope.visible if @status_filter == "visible"
      scope = scope.hidden if @status_filter == "hidden"

      if @query.present?
        pattern = "%#{Review.sanitize_sql_like(@query)}%"
        scope = scope.left_joins(:product, :user)
                     .where(
                       "reviews.comment ILIKE :pattern OR products.name ILIKE :pattern OR users.name ILIKE :pattern",
                       pattern: pattern
                     )
      end

      @pagy, @reviews = pagy(scope, items: 20)

      set_admin_page(
        title: "Product reviews",
        subtitle: "Moderate customer feedback from your store"
      )
    end

    def update
      case params[:visibility]
      when "hide"
        @review.hide!
        notice = "Review hidden."
      when "show"
        @review.show!
        notice = "Review made visible."
      else
        flash[:error] = "Invalid visibility option."
        return redirect_to admin_reviews_path(redirect_filters), status: :see_other
      end

      redirect_to admin_reviews_path(redirect_filters), notice: notice, status: :see_other
    end

    def destroy
      @review.destroy
      redirect_to admin_reviews_path(redirect_filters), notice: "Review deleted.", status: :see_other
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def redirect_filters
      params.permit(:query, :status, :page).to_h.compact_blank
    end
  end
end
