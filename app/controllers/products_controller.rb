# frozen_string_literal: true

class ProductsController < ApplicationController
  CATEGORY_FILTERS = {
    "all" => {
      name: "All products",
      description: "Browse the entire BanHang catalogue."
    },
    "budget" => {
      name: "Budget finds",
      description: "Wallet-friendly picks under $50."
    },
    "premium" => {
      name: "Premium picks",
      description: "Standout items that cost $200 or more."
    }
  }.freeze

  SORT_OPTIONS = {
    "newest" => "Newest arrivals",
    "price_low_high" => "Price: Low to High",
    "price_high_low" => "Price: High to Low"
  }.freeze

  helper_method :category_filters, :sort_options, :active_category

  def index
    @selected_category = sanitize_category(params[:category])
    @selected_sort = sanitize_sort(params[:sort])

    set_page_metadata(
      title: "Shop products",
      description: "Browse featured BanHang products across every price point, then filter or sort to find the perfect match.",
      canonical: canonical_listing_url
    )

    @products = Product.all
    @products = apply_category_filter(@products)
    @products = apply_sort(@products)

    respond_to do |format|
      format.html
    end
  end

  private

  def category_filters
    CATEGORY_FILTERS
  end

  def sort_options
    SORT_OPTIONS
  end

  def active_category
    category_filters[@selected_category]
  end

  def sanitize_category(category)
    category_filters.key?(category) ? category : "all"
  end

  def sanitize_sort(sort)
    sort_options.key?(sort) ? sort : "newest"
  end

  def apply_category_filter(scope)
    case @selected_category
    when "budget"
      scope.where(Product.arel_table[:price].lt(50))
    when "premium"
      scope.where(Product.arel_table[:price].gteq(200))
    else
      scope
    end
  end

  def apply_sort(scope)
    case @selected_sort
    when "price_low_high"
      scope.order(price: :asc)
    when "price_high_low"
      scope.order(price: :desc)
    else
      scope.order(created_at: :desc)
    end
  end

  def canonical_listing_url
    products_url
  end
end
