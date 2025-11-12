# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Checkout
  class OrderProcessor
    class Error < StandardError; end
    class CartEmptyError < Error; end
    class StockError < Error; end

    def initialize(user:, cart:, shipping:, currency: CurrencyConverter.base_currency)
      @user = user
      @cart = cart
      @shipping = shipping
      @currency = currency.to_s.upcase.presence || CurrencyConverter.base_currency
    end

    def call
      @cart.preload_products
      raise CartEmptyError, "Your cart is empty." if @cart.empty?

      items = @cart.items_with_products

      order, low_stock_ids = ApplicationRecord.transaction do
        locked_products = lock_products(items)
        order = build_order(locked_products, items)
        order.save!
        low_stock_ids = adjust_stock!(locked_products, items)
        [order, low_stock_ids]
      end

      enqueue_notifications(order, low_stock_ids)

      order
    end

    private

    def lock_products(items)
      product_ids = items.map(&:product_id).uniq
      products = Product.lock.where(id: product_ids).index_by(&:id)

      missing_ids = product_ids - products.keys
      raise StockError, "One or more products are no longer available." if missing_ids.any?

      products
    end

    def build_order(products, items)
      # Determine shop from user or from first product
      shop = @user.shop || products.values.first&.shop
      
      order = Order.new(
        user: @user,
        shop: shop,
        status: "pending",
        placed_at: Time.current,
        currency: @currency,
        exchange_rate: exchange_rate_for(@currency)
      )

      items.each do |item|
        product = products[item.product_id]
        verify_stock!(product, item.quantity)

        unit_price = product.price
        total_price = unit_price * item.quantity
        unit_price_local = CurrencyConverter.convert(unit_price, from: CurrencyConverter.base_currency, to: @currency)
        total_price_local = unit_price_local * item.quantity

        order.order_items.build(
          product: product,
          quantity: item.quantity,
          unit_price: unit_price,
          total_price: total_price,
          currency: @currency,
          exchange_rate: exchange_rate_for(@currency),
          unit_price_local: unit_price_local,
          total_price_local: total_price_local
        )
      end

      order.total = order.order_items.sum { |order_item| order_item.total_price }
      order_total_local = CurrencyConverter.convert(order.total, from: CurrencyConverter.base_currency, to: @currency)
      order.total_local_amount = order_total_local
      order
    end

    def adjust_stock!(products, items)
      low_stock_ids = []

      items.each do |item|
        product = products[item.product_id]
        next unless product

        new_stock = product.stock.to_i - item.quantity
        product.update!(stock: new_stock)
        low_stock_ids << product.id if new_stock < 5
      end

      low_stock_ids
    end

    def verify_stock!(product, requested_quantity)
      available = product.stock.to_i
      return if requested_quantity <= available

      if available.zero?
        raise StockError, "#{product.name} is no longer available."
      end

      raise StockError, "Only #{available} #{'unit'.pluralize(available)} of #{product.name} remain."
    end

    def enqueue_notifications(order, low_stock_ids)
      OrderConfirmationJob.perform_later(order.id)
      low_stock_ids.uniq.each { |product_id| LowStockAlertJob.perform_later(product_id) }
    end

    def exchange_rate_for(currency)
      CurrencyRate.fetch_rate(currency).rate_to_base
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
