# frozen_string_literal: true

module Admin
  class ShopsController < ApplicationController
    before_action :ensure_master_admin!
    before_action :set_shop, only: :show

    def index
      @shops = Shop.includes(:admin_users, :shop_features).order(:name)
      @total_features = Feature.count
      shop_ids = @shops.map(&:id)
      unlocked_scope = ShopFeature.where(shop_id: shop_ids, status: ShopFeature.statuses[:unlocked])
      @unlocked_counts = unlocked_scope.group(:shop_id).count

      set_admin_page(
        title: "Shops",
        subtitle: "Manage feature availability across all shops"
      )
    end

    def show
      redirect_to admin_shop_features_path(@shop)
    end

    private

    def set_shop
      @shop = Shop.find(params[:id])
    end
  end
end
