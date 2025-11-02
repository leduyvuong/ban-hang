# frozen_string_literal: true

require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Ceramics")
    @other_category = Category.create!(name: "Snacks")

    @ceramic_bowl = Product.create!(
      name: "Handmade Ceramic Bowl",
      description: "Crafted with natural glaze.",
      price: "24.00",
      stock: 5,
      category: @category
    )

    @snack_pack = Product.create!(
      name: "Dried Mango Pack",
      description: "Sweet and tangy slices.",
      price: "8.50",
      stock: 0,
      category: @other_category
    )
  end

  test "index renders successfully" do
    get products_url
    assert_response :success
    assert_select "h1", "Products"
    assert_select "a", text: @ceramic_bowl.name
  end

  test "search filters results" do
    get products_url, params: { search: "ceramic" }
    assert_response :success
    assert_select "a", text: @ceramic_bowl.name
    assert_select "a", text: @snack_pack.name, count: 0
  end

  test "stock status filter limits to in-stock products" do
    get products_url, params: { stock_status: "in_stock" }
    assert_response :success
    assert_select "a", text: @ceramic_bowl.name
    assert_select "a", text: @snack_pack.name, count: 0
  end

  test "category filter scopes results" do
    get products_url, params: { category: @category.slug }
    assert_response :success
    assert_select "a", text: @ceramic_bowl.name
    assert_select "a", text: @snack_pack.name, count: 0
  end

  test "pagination parameters render navigation" do
    15.times do |index|
      Product.create!(
        name: "Extra Product #{index}",
        description: "Additional item #{index}",
        price: (index + 1).to_s,
        stock: 2,
        category: @category
      )
    end

    get products_url, params: { page: 2 }
    assert_response :success
    assert_select "nav[aria-label='Pagination']"
  end
end
