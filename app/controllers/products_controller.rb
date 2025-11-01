# frozen_string_literal: true

class ProductsController < ApplicationController
  SORT_OPTIONS = {
    "newest" => "Newest arrivals",
    "price_low_high" => "Price: Low to High",
    "price_high_low" => "Price: High to Low"
  }.freeze

  LISTING_DESCRIPTION = <<~TEXT.squish
    Browse featured BanHang products across every price point,
    then filter or sort to find the perfect match.
  TEXT

  helper_method :categories, :sort_options, :active_category

  before_action :set_product, only: %i[show modal]
  before_action :load_categories, only: %i[index]

  def index
    @selected_category = sanitize_category(params[:category])
    @selected_sort = sanitize_sort(params[:sort])

    set_page_metadata(
      title: "Shop products",
      description: LISTING_DESCRIPTION,
      canonical: canonical_listing_url
    )

    @products = Product.includes(:category).all
    @products = apply_category_filter(@products)
    @products = apply_sort(@products)
    @featured_product = @products.first

    respond_to(&:html)
  end

  def show
    description = product_meta_description(@product).presence || ApplicationHelper::DEFAULT_META_DESCRIPTION

    set_page_metadata(
      title: @product.name,
      description: description,
      canonical: product_url(@product)
    )

    assign_open_graph(description)

    respond_to(&:html)
  end

  def modal
    description = product_meta_description(@product).presence || ApplicationHelper::DEFAULT_META_DESCRIPTION

    assign_open_graph(description)

    render partial: "products/modal", locals: { product: @product }, formats: [:html], layout: false
  end

  private

  def categories
    @categories
  end

  def sort_options
    SORT_OPTIONS
  end

  def active_category
    return if @selected_category == "all"

    categories.find { |category| category.slug == @selected_category }
  end

  def sanitize_category(category)
    return "all" if category.blank?
    return category if categories.any? { |c| c.slug == category }

    "all"
  end

  def sanitize_sort(sort)
    sort_options.key?(sort) ? sort : "newest"
  end

  def apply_category_filter(scope)
    return scope if @selected_category == "all"

    category = categories.find { |c| c.slug == @selected_category }
    return scope unless category

    scope.where(category: category)
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

  def set_product
    @product = Product.find_by_slug_or_id!(params[:id])
  end

  def load_categories
    @categories = Category.order(:name)
  end

  def product_meta_description(product)
    summary = product.short_description.presence || product.description
    summary = ActionController::Base.helpers.strip_tags(summary.to_s)
    ActionController::Base.helpers.truncate(summary, length: 155, separator: " ")
  end

  def assign_open_graph(description)
    @open_graph = {
      title: @product.name,
      description: description,
      image: @product.image_url,
      url: product_url(@product),
      type: "product"
    }
  end
end
