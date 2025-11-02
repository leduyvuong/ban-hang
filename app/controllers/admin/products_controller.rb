# frozen_string_literal: true

module Admin
  class ProductsController < ApplicationController
    before_action :set_product, only: %i[show edit update destroy]
    before_action :load_categories, only: %i[new create edit update]

    def index
      @query = params[:query].to_s.strip
      @category_filter = params[:category].presence
      @stock_filter = params[:stock_status].presence

      scope = Product.includes(:category, image_attachment: { blob: :variant_records })
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
      if @product.save
        redirect_to admin_product_path(@product), notice: "Product created successfully."
      else
        flash.now[:error] = @product.errors.full_messages.to_sentence
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

      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Product updated successfully."
      else
        flash.now[:error] = @product.errors.full_messages.to_sentence
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
      @product = Product.find_by_slug_or_id!(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :short_description, :price, :stock, :image, :category_id)
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
  end
end
