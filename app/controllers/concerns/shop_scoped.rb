# frozen_string_literal: true

module ShopScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_shop
    helper_method :current_shop
  end

  private

  def set_current_shop
    return if defined?(@current_shop)

    admin_user = respond_to?(:current_admin_user, true) ? current_admin_user : nil
    
    # Use shop_from_params if available (defined in ApplicationController)
    shop_from_url = respond_to?(:shop_from_params, true) ? shop_from_params : nil

    @current_shop = shop_from_url ||
                    current_user&.owned_shop ||
                    current_user&.shop ||
                    current_user&.shops&.first ||
                    admin_user&.shop ||
                    Shop.active.first ||
                    Shop.first
  end

  def current_shop
    set_current_shop unless defined?(@current_shop)
    @current_shop
  end

  def scope_to_shop(relation)
    return relation unless current_shop

    relation.where(shop: current_shop)
  end
end
