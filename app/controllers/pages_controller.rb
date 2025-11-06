# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    @shop = Shop.first
    @published_page = @shop&.pages&.published&.order(published_at: :desc)&.first

    if @published_page&.components&.any?
      @layout_components = @published_page.ordered_components
    else
      @featured_products = Rails.cache.fetch("home/featured_products", expires_in: 10.minutes) do
        Product.includes(:category, image_attachment: { blob: :variant_records }).order(created_at: :desc).limit(6).to_a
      end

      @categories = Rails.cache.fetch("home/featured_categories", expires_in: 10.minutes) do
        Category.order(:name).includes(:products).limit(6).to_a
      end
    end

    @newsletter_subscription = NewsletterSubscription.new
  end
end
