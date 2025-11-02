# frozen_string_literal: true

module Admin
  class FeaturesController < ApplicationController
    before_action :ensure_master_admin!
    before_action :set_shop

    def index
      @features = Feature.order(:category, :name)
      @shop_features = @shop.shop_features.includes(:feature).index_by(&:feature_id)
      @unlocked_feature_count = @shop_features.values.count { |shop_feature| shop_feature.unlocked? }

      set_admin_page(
        title: "#{@shop.name} Features",
        subtitle: "Unlock capabilities for this shop"
      )
    end

    def unlock
      feature = Feature.find(params[:id])

      if @shop.feature_unlocked?(feature.slug)
        redirect_to admin_shop_features_path(@shop), alert: "#{feature.name} is already unlocked."
        return
      end

      @shop.unlock_feature!(feature.slug, unlocked_by: current_admin_user)

      redirect_to admin_shop_features_path(@shop), notice: "#{feature.name} unlocked for #{@shop.name}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_shop_features_path(@shop), alert: e.record.errors.full_messages.to_sentence
    end

    private

    def set_shop
      @shop = Shop.find(params[:shop_id])
    end
  end
end
