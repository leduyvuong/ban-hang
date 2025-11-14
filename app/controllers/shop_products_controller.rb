# frozen_string_literal: true

class ShopProductsController < ApplicationController
  before_action :set_current_shop

  def index
    @shop = current_shop
    @categories = @shop.categories.order(:name)
    @products = @shop.products.includes(:category, image_attachment: { blob: :variant_records })
                              .order(created_at: :desc)
    if params[:category].present?
      @selected_category = @categories.find { |category| category.slug == params[:category] }
      @products = @products.where(category: @selected_category) if @selected_category
    end
    set_page_metadata(title: "#{@shop.name} products", description: "Explore products available at #{@shop.name}")
  end
end
