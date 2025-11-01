# frozen_string_literal: true

class PagesController < ApplicationController

  def home
    @featured_products = Product.includes(:category).order(created_at: :desc).limit(6)
    @categories = Category.includes(:products).order(:name).limit(6)
    @newsletter_subscription = NewsletterSubscription.new
  end
end
