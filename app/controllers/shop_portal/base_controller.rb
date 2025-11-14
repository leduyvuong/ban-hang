# frozen_string_literal: true

module ShopPortal
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_login!
    before_action :assign_current_shop
    before_action :ensure_shop_owner_or_staff

    helper AdminHelper
    helper_method :shop

    private

    def assign_current_shop
      @current_shop = set_current_shop
    end

    def shop
      @current_shop
    end
  end
end
