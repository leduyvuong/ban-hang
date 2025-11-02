# frozen_string_literal: true

require "test_helper"

class CartTest < ActiveSupport::TestCase
  test "cart item validates stock availability" do
    product = Product.create!(
      name: "Limited Edition Tee",
      price: "25.50",
      stock: 0
    )

    item = Cart::Item.new(product_id: product.id, quantity: 1)
    item.product = product

    refute item.valid?
    assert_includes item.errors.full_messages, "#{product.name} is currently out of stock."
  end

  test "add_item raises when requested quantity exceeds stock" do
    product = Product.create!(
      name: "Cap",
      price: "15.00",
      stock: 1
    )

    cart = Cart.new
    cart.add_item(product.id, 1)

    error = assert_raises(Cart::OutOfStockError) do
      cart.add_item(product.id, 1)
    end

    assert_equal "Only 1 unit of #{product.name} available.", error.message
    assert_equal 1, cart.items.first.quantity
  end

  test "update_item refuses quantities beyond available stock" do
    product = Product.create!(
      name: "Sneakers",
      price: "80.00",
      stock: 2
    )

    cart = Cart.new
    cart.add_item(product.id, 1)

    product.update!(stock: 1)

    error = assert_raises(Cart::OutOfStockError) do
      cart.update_item(product.id, 3)
    end

    assert_match(/Only 1 unit/, error.message)
    assert_equal 1, cart.items.first.quantity
  end
end
