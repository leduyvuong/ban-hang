# frozen_string_literal: true

require "test_helper"
require "bigdecimal"
require "securerandom"

module Checkout
  class OrderProcessorTest < ActiveSupport::TestCase
    setup do
      @user = build_user
      @shipping = {
        "name" => "Test User",
        "address" => "123 Rails Street",
        "city" => "Ruby City",
        "postal_code" => "12345",
        "phone" => "555-0100"
      }
    end

    test "creates an order, snapshots pricing, and decrements stock" do
      product = Product.create!(
        name: "Desk Lamp",
        price: "49.99",
        stock: 3
      )

      cart = Cart.new
      cart.add_item(product.id, 2)

      order = Checkout::OrderProcessor.new(user: @user, cart: cart, shipping: @shipping).call

      assert order.persisted?
      assert_equal @user, order.user
      assert_equal 1, order.order_items.size
      assert_equal BigDecimal("99.98"), order.total
      assert_equal 1, product.reload.stock
      assert_equal 2, order.order_items.first.quantity
      assert_equal BigDecimal("49.99"), order.order_items.first.unit_price
    end

    test "prevents race conditions causing overselling" do
      product = Product.create!(
        name: "Limited Run Poster",
        price: "30.00",
        stock: 1
      )

      cart_one = Cart.new
      cart_one.add_item(product.id, 1)

      cart_two = Cart.new
      cart_two.add_item(product.id, 1)

      processor_one = Checkout::OrderProcessor.new(user: @user, cart: cart_one, shipping: @shipping)
      processor_two = Checkout::OrderProcessor.new(user: @user, cart: cart_two, shipping: @shipping)

      results = []
      mutex = Mutex.new

      threads = [processor_one, processor_two].map do |processor|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              order = processor.call
              mutex.synchronize { results << order }
            rescue Checkout::OrderProcessor::StockError => e
              mutex.synchronize { results << e }
            end
          end
        end
      end

      threads.each(&:join)

      assert_equal 2, results.size
      assert results.any? { |entry| entry.is_a?(Order) }, "expected one successful order"
      assert results.any? { |entry| entry.is_a?(Checkout::OrderProcessor::StockError) }, "expected a stock error for the second checkout"
      assert_equal 0, product.reload.stock
      assert_equal 1, Order.count
    end

    private

    def build_user
      User.create!(
        name: "Checkout Tester",
        email: "checkout-#{SecureRandom.hex(4)}@example.com",
        password: "password123"
      )
    end
  end
end
