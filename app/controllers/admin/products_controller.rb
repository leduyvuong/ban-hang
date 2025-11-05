# frozen_string_literal: true

module Admin
  class ProductsController < ApplicationController
    before_action :set_product, only: %i[show edit update destroy]
    before_action :load_categories, only: %i[new create edit update]
    before_action :load_discounts, only: %i[new edit update]
    before_action :normalize_pricing_params, only: %i[create update]

    def index
      @query = params[:query].to_s.strip
      @category_filter = params[:category].presence
      @stock_filter = params[:stock_status].presence

      scope = Product.includes(:category, { product_discount: :discount }, image_attachment: { blob: :variant_records })
      scope = scope.matching_query(@query)
      scope = scope.with_category_slug(@category_filter) if @category_filter.present?
      scope = scope.with_stock_status(@stock_filter) if @stock_filter.present?
      scope = scope.order(created_at: :desc)

      @pagy, @products = pagy(scope, items: 20)
      @categories = Category.order(:name)

      set_admin_page(
        title: "Products",
        subtitle: "Manage your catalogue",
        actions: render_to_string(partial: "admin/shared/primary_actions", locals: { actions: [
          { label: "New product", url: new_admin_product_path, style: "primary" }
        ] })
      )
    end

    def new
      @product = Product.new
      set_admin_page(title: "New product", subtitle: "Add a product to your catalogue")
    end

    def create
      @product = Product.new(product_params)
      success = Product.transaction do
        next false unless @product.save

        apply_product_discount(@product)
      end

      if success
        redirect_to admin_product_path(@product), notice: "Product created successfully."
      else
        flash.now[:error] = @product.errors.full_messages.to_sentence
        load_discounts
        set_admin_page(title: "New product", subtitle: "Add a product to your catalogue")
        render :new, status: :unprocessable_entity
      end
    end

    def show
      set_admin_page(title: @product.name, subtitle: "Product details")
    end

    def edit
      set_admin_page(title: "Edit product", subtitle: @product.name)
    end

    def update
      purge_image_if_requested

      success = Product.transaction do
        next false unless @product.update(product_params)

        apply_product_discount(@product)
      end

      if success
        redirect_to admin_product_path(@product), notice: "Product updated successfully."
      else
        flash.now[:error] = @product.errors.full_messages.to_sentence
        load_discounts
        set_admin_page(title: "Edit product", subtitle: @product.name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "Product deleted."
    end

    private

    def set_product
      @product = Product.includes(product_discount: :discount).find_by_slug_or_id!(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :short_description, :price, :price_local_amount, :price_currency, :stock, :image, :category_id)
    end

    def load_discounts
      base_scope = Discount.currently_active.order(:name)
      @discounts = base_scope.to_a

      if @product&.discount.present? && @discounts.exclude?(@product.discount)
        @discounts << @product.discount
      end

      @discounts.sort_by!(&:name)

      selected_param = params.dig(:product, :discount_id)
      @selected_discount_id = if selected_param == ""
        ""
      elsif selected_param.present?
        selected_param
      else
        @product&.discount&.id
      end
    end

    def load_categories
      @categories = Rails.cache.fetch("admin/categories", expires_in: 1.hour) do
        Category.order(:name).to_a
      end
    end

    def purge_image_if_requested
      return unless params.dig(:product, :remove_image) == "1"

      @product.image.purge_later if @product.image.attached?
    end

    def normalize_pricing_params
      product_hash = params[:product]
      return unless product_hash

      local_amount = product_hash[:price_local_amount].presence || product_hash[:price].presence
      currency_code = product_hash[:price_currency].presence || current_currency
      return if local_amount.blank?

      converted = CurrencyConverter.convert(local_amount, from: currency_code, to: CurrencyConverter.base_currency)
      product_hash[:price] = converted
      product_hash[:price_local_amount] = local_amount
      product_hash[:price_currency] = currency_code.upcase
    rescue CurrencyConverter::ConversionError => e
      flash.now[:error] = e.message
      product_hash[:price] = nil
    end

    def apply_product_discount(product)
      discount_param = params.dig(:product, :discount_id)
      return true if discount_param.nil?

      if discount_param.blank?
        product.product_discount&.destroy
        return true
      end

      discount = Discount.find_by(id: discount_param)
      unless discount
        product.errors.add(:base, "Selected discount could not be found.")
        raise ActiveRecord::Rollback
      end

      record = product.product_discount || product.build_product_discount
      return true if record.discount_id == discount.id && record.persisted?

      record.discount = discount

      unless record.save
        record.errors.full_messages.each { |message| product.errors.add(:base, message) }
        raise ActiveRecord::Rollback
      end

      true
    end
  end
end
