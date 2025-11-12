# frozen_string_literal: true

module Admin
  class StorefrontSettingsController < ApplicationController
    before_action :set_shop
    before_action :ensure_shop_present!
    before_action :load_shops

    helper_method :can_switch_between_shops?

    def show
      prepare_page
    end

    def update
      if @shop.update(storefront_settings_params)
        redirect_to admin_storefront_settings_path(shop_id: @shop.id), notice: "Homepage preference updated successfully."
      else
        prepare_page
        flash.now[:alert] = @shop.errors.full_messages.to_sentence.presence || "Unable to update homepage preference."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_shop
      @shop = if can_switch_between_shops?
                find_shop_from_params || Shop.order(:name).first
              else
                current_admin_user&.shop || current_user&.shop || Shop.first
              end
    end

    def find_shop_from_params
      return if params[:shop_id].blank?

      Shop.find_by(id: params[:shop_id])
    end

    def load_shops
      @available_shops = Shop.order(:name) if can_switch_between_shops?
    end

    def ensure_shop_present!
      return if @shop.present?

      redirect_to admin_root_path, alert: "No shop available to configure."
    end

    def storefront_settings_params
      params.require(:shop).permit(:homepage_variant)
    end

    def can_switch_between_shops?
      current_admin_user&.is_master_admin? || current_user&.admin?
    end

    def prepare_page
      set_admin_page(
        title: "Storefront settings",
        subtitle: "Điều chỉnh giao diện trang chủ hiển thị với khách hàng.",
        actions: view_context.link_to(
          "Xem trang chủ",
          root_path,
          class: "inline-flex items-center gap-2 rounded-full bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-500"
        )
      )
    end
  end
end
