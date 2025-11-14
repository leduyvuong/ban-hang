# frozen_string_literal: true

module Admin
  module Shops
    class ProductsController < Admin::ApplicationController
      before_action :set_shop

      def index
        @products = @shop.products.includes(:category).order(created_at: :desc)
        set_admin_page(title: "Products", subtitle: @shop.name)
      end

      private

      def set_shop
        @shop = Shop.find(params[:shop_id])
      end
    end
  end
end
