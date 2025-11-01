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
end
