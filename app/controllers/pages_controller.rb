# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    @shops = Rails.cache.fetch("home/shops", expires_in: 10.minutes) do
      Shop.publicly_visible.includes(:owner, :products).limit(6).to_a
    end

    @featured_products = if current_shop.present?
      cache_key = ["home/featured_products", current_shop.id]
      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        current_shop.products.includes(:category, image_attachment: { blob: :variant_records }).order(created_at: :desc).limit(6).to_a
      end
    else
      []
    end

    @categories = if current_shop.present?
      cache_key = ["home/featured_categories", current_shop.id]
      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        current_shop.categories.order(:name).limit(6).to_a
      end
    else
      []
    end

    @newsletter_subscription = NewsletterSubscription.new
  end
end
