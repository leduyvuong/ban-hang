# frozen_string_literal: true

class PagesController < ApplicationController

  def home
    @featured_products = Rails.cache.fetch("home/featured_products", expires_in: 10.minutes) do
      Product.includes({ product_discount: :discount }, image_attachment: { blob: :variant_records }).order(created_at: :desc).limit(6).to_a
    end

    @categories = Rails.cache.fetch("home/featured_categories", expires_in: 10.minutes) do
      Category.order(:name).limit(6).to_a
    end

    @newsletter_subscription = NewsletterSubscription.new
  end
end
