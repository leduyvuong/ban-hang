# frozen_string_literal: true

class WishlistsController < ApplicationController
  before_action :require_login!

  def show
    @wishlist_items = current_user.wishlist_items.includes(product: [
      :category,
      { product_discount: :discount },
      image_attachment: { blob: :variant_records }
    ]).order(created_at: :desc)
  end
end
