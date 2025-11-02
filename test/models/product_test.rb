# frozen_string_literal: true

require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "requires name and price" do
    product = Product.new
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
    assert_includes product.errors[:price], "can't be blank"
  end

  test "price cannot be negative" do
    product = Product.new(name: "Test", price: -1)
    assert_not product.valid?
    assert_includes product.errors[:price], "must be greater than or equal to 0"
  end

  test "matching_query finds products by name and description" do
    Product.delete_all
    tea = Product.create!(
      name: "Lotus Flower Tea",
      description: "Fragrant lotus petals with calming aroma.",
      price: "12.50",
      stock: 5
    )
    Product.create!(
      name: "Coffee Beans",
      description: "Bold roast from the central highlands.",
      price: "18.00",
      stock: 10
    )

    result = Product.matching_query("lotus")
    assert_includes result, tea
    assert_equal 1, result.count
  end

  test "with_stock_status filters in-stock and out-of-stock items" do
    Product.delete_all
    in_stock = Product.create!(name: "Bamboo Chopsticks", price: "4.00", stock: 3)
    Product.create!(name: "Vintage Poster", price: "15.00", stock: 0)

    records = Product.with_stock_status("in_stock")
    assert_includes records, in_stock
    assert records.all? { |product| product.stock.positive? }

    none = Product.with_stock_status("out_of_stock")
    assert_equal 1, none.count
    assert none.all? { |product| product.stock.zero? }
  end

  test "ordered_by_param sorts products by accepted keys" do
    Product.delete_all
    cheaper = Product.create!(name: "Ceramic Cup", price: "9.00", stock: 5)
    pricier = Product.create!(name: "Ceramic Teapot", price: "35.00", stock: 5)

    price_desc = Product.ordered_by_param("price_high_low").first
    assert_equal pricier, price_desc

    name_sorted = Product.ordered_by_param("name_az").first
    assert_equal cheaper, name_sorted
  end
end
