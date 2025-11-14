# frozen_string_literal: true

module ShopPortal
  class ProductsController < BaseController
    def index
      @products = shop.products.includes(:category).order(created_at: :desc)
      @page_title = "Products"
      @admin_page_title = "Shop products"
      @admin_page_subtitle = shop.name
    end
  end
end
