# frozen_string_literal: true

module ShopPortal
  class CategoriesController < BaseController
    def index
      @categories = shop.categories.includes(:products).order(:name)
      @page_title = "Categories"
      @admin_page_title = "Shop categories"
      @admin_page_subtitle = shop.name
    end
  end
end
