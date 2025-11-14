# frozen_string_literal: true

class ShopsController < ApplicationController
  before_action :set_current_shop, only: :show

  def index
    @shops = Shop.publicly_visible.includes(:owner, :products, :categories).order(:name)
    set_page_metadata(title: "Shops", description: "Browse all storefronts on BanHang")
  end

  def show
    @shop = current_shop
    @categories = @shop.categories.includes(:products).order(:name)
    @products = @shop.products.includes(:category, image_attachment: { blob: :variant_records })
                              .order(created_at: :desc)
                              .limit(9)
    set_page_metadata(title: @shop.name, description: "Discover products and categories from #{@shop.name}")
  end
end
