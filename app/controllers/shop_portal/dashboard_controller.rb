# frozen_string_literal: true

module ShopPortal
  class DashboardController < BaseController
    def index
      @products_count = shop.products.count
      @categories_count = shop.categories.count
      @recent_products = shop.products.order(created_at: :desc).limit(5)
      @page_title = "Dashboard"
      @admin_page_title = "Shop dashboard"
      @admin_page_subtitle = shop.name
    end
  end
end
