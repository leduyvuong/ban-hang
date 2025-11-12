# frozen_string_literal: true

module Products
  class WishlistsController < ApplicationController
    before_action :require_login!
    before_action :set_product

    def create
      current_user.wishlist_items.find_or_create_by!(product: @product)
      flash[:success] = "Added to your wishlist."
      redirect_to product_path(@product)
    end

    def destroy
      item = current_user.wishlist_items.find_by(product: @product)
      item&.destroy!
      flash[:success] = "Removed from your wishlist."
      redirect_to product_path(@product), status: :see_other
    end

    private

    def set_product
      @product = Product.find_by_slug_or_id!(params[:product_id])
    end
  end
end
