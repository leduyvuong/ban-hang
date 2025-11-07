# frozen_string_literal: true

class ProductsController < ApplicationController
  SORT_OPTIONS = {
    "newest" => "Newest arrivals",
    "price_low_high" => "Price: Low to High",
    "price_high_low" => "Price: High to Low",
    "name_az" => "Name: A-Z"
  }.freeze

  STOCK_FILTERS = {
    "in_stock" => "In Stock",
    "out_of_stock" => "Out of Stock"
  }.freeze

  LISTING_DESCRIPTION = <<~TEXT.squish
    Browse featured BanHang products across every price point,
    then filter or sort to find the perfect match.
  TEXT

  helper_method :categories, :sort_options, :stock_filters, :active_category

  before_action :set_product, only: %i[show modal]
  before_action :load_categories, only: %i[index]

  def index
    build_filters

    set_page_metadata(
      title: "Shop products",
      description: LISTING_DESCRIPTION,
      canonical: canonical_listing_url
    )

    base_scope = Product.includes(:category, { product_discount: :discount }, image_attachment: { blob: :variant_records })
    scoped_products = apply_filters(base_scope)
    freshness_token = scoped_products.reorder(nil).maximum(:updated_at)&.to_i
    @pagy, @products = pagy(scoped_products, items: 12, page: sanitized_page)
    @results_count = @pagy.count
    @range_start = @pagy.from
    @range_end = @pagy.to
    @has_active_filters = filters_active?
    @list_cache_key = [
      "products/list",
      @pagy.page,
      @search_term,
      @selected_category,
      @selected_sort,
      @min_price,
      @max_price,
      @stock_status,
      freshness_token
    ]

    if turbo_frame_request?
      render partial: "products/list_frame",
             locals: {
               products: @products,
               pagy: @pagy,
               search_term: @search_term,
               sort_options: SORT_OPTIONS,
               selected_sort: @selected_sort,
               list_cache_key: @list_cache_key
             },
             layout: false
    else
      render :index
    end
  end

  def show
    description = product_meta_description(@product).presence || ApplicationHelper::DEFAULT_META_DESCRIPTION

    set_page_metadata(
      title: @product.name,
      description: description,
      canonical: product_url(@product)
    )

    assign_open_graph(description)

    @reviews = @product.visible_reviews.includes(:user).recent_first
    @user_review = current_user&.review_for(@product)
    @wishlist_item_present = current_user&.wishlisted_product?(@product)

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

  def stock_filters
    STOCK_FILTERS
  end

  def active_category
    return if @selected_category == "all"

    categories.find { |category| category.slug == @selected_category }
  end

  def canonical_listing_url
    products_url
  end

  def set_product
    @product = Product.includes(:category, { product_discount: :discount }, image_attachment: { blob: :variant_records }).find_by_slug_or_id!(params[:id])
  end

  def load_categories
    @categories = Rails.cache.fetch("product_filters/categories", expires_in: 30.minutes) do
      Category.order(:name).to_a
    end
  end

  def filter_params
    params.permit(:category, :sort, :search, :min_price, :max_price, :stock_status, :page)
  end

  def build_filters
    @search_term = filter_params[:search].to_s.strip.presence
    @selected_category = sanitize_category(filter_params[:category])
    @selected_sort = sanitize_sort(filter_params[:sort])
    @min_price = parse_price(filter_params[:min_price])
    @max_price = parse_price(filter_params[:max_price])
    @stock_status = sanitize_stock(filter_params[:stock_status])
  end

  def sanitized_page
    page = filter_params[:page].to_i
    page >= 1 ? page : 1
  end

  def apply_filters(scope)
    scoped = scope.matching_query(@search_term)
    scoped = scoped.with_category_slug(@selected_category) unless @selected_category == "all"
    scoped = scoped.with_min_price(@min_price)
    scoped = scoped.with_max_price(@max_price)
    scoped.with_stock_status(@stock_status).ordered_by_param(@selected_sort)
  end

  def sanitize_category(category)
    return "all" if category.blank?
    return category if categories.any? { |c| c.slug == category }

    "all"
  end

  def sanitize_sort(sort)
    sort_options.key?(sort) ? sort : "newest"
  end

  def sanitize_stock(stock)
    stock_filters.key?(stock) ? stock : nil
  end

  def parse_price(value)
    return if value.blank?

    BigDecimal(value)
  rescue ArgumentError
    nil
  end

  def filters_active?
    @search_term.present? ||
      @selected_category != "all" ||
      @min_price.present? ||
      @max_price.present? ||
      @stock_status.present?
  end

  def product_meta_description(product)
    summary = product.short_description.presence || product.description
    summary = ActionController::Base.helpers.strip_tags(summary.to_s)
    ActionController::Base.helpers.truncate(summary, length: 155, separator: " ")
  end

  def assign_open_graph(description)
    og_image = if @product.image.attached?
      helpers.url_for(@product.image_variant(width: 1200, height: 630))
    end

    @open_graph = {
      title: @product.name,
      description: description,
      image: og_image,
      url: product_url(@product),
      type: "product"
    }
  end
end
