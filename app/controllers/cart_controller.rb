# frozen_string_literal: true

class CartController < ApplicationController
  rescue_from Cart::OutOfStockError, with: :handle_out_of_stock

  before_action :load_cart

  def show
    @cart.preload_products
    persist_cart!

    set_page_metadata(
      title: "Your cart",
      description: "Review your BanHang cart, adjust quantities, or continue shopping before checkout.",
      canonical: cart_url,
      robots: "noindex"
    )
  end

  def mini
    @cart.preload_products
    persist_cart!

    respond_to do |format|
      format.html { render partial: "cart/mini", locals: { cart: @cart } }
      format.json { render_cart_payload }
    end
  end

  def add_item
    product = find_product
    @cart.add_item(product.id, params[:quantity].presence || 1)
    finalize_update

    respond_to do |format|
      format.html { redirect_back fallback_location: products_path, notice: "#{product.name} was added to your cart." }
      format.json { render_cart_payload(status: :created, message: "#{product.name} was added to your cart.") }
    end
  end

  def update_item
    product = find_product
    @cart.update_item(product.id, params[:quantity].presence || 1)
    finalize_update

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{product.name} was updated." }
      format.json { render_cart_payload(message: "#{product.name} was updated.") }
    end
  end

  def remove_item
    product = find_product
    @cart.remove_item(product.id)
    finalize_update

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{product.name} was removed from your cart." }
      format.json { render_cart_payload(message: "#{product.name} was removed from your cart.") }
    end
  end

  def clear
    @cart.clear
    finalize_update

    respond_to do |format|
      format.html { redirect_to products_path, notice: "Your cart is empty." }
      format.json { render_cart_payload(message: "Your cart was cleared.") }
    end
  end

  private

  def load_cart
    @cart = current_cart
  end

  def find_product
    Product.find_by_slug_or_id!(params[:product_id])
  end

  def finalize_update
    @cart.preload_products
    persist_cart!
  end

  def render_cart_payload(status: :ok, message: nil)
    render json: {
      mini: render_to_string(partial: "cart/mini", formats: [:html], locals: { cart: @cart }),
      drawer: render_to_string(partial: "cart/drawer", formats: [:html], locals: { cart: @cart }),
      full_items: render_to_string(partial: "cart/items", formats: [:html], locals: { cart: @cart, compact: false }),
      summary: render_to_string(partial: "cart/summary", formats: [:html], locals: { cart: @cart, compact: false }),
      count: @cart.total_items,
      subtotal: helpers.number_to_currency(@cart.subtotal),
      message: message
    }, status: status
  end

  def handle_out_of_stock(error)
    respond_to do |format|
      format.html { redirect_back fallback_location: cart_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
      format.turbo_stream do
        flash[:alert] = error.message
        redirect_back fallback_location: cart_path
      end
    end
  end
end
