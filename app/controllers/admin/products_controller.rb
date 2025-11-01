# frozen_string_literal: true

module Admin
  class ProductsController < ApplicationController
    before_action :set_product, only: %i[show edit update destroy]
    before_action :load_categories, only: %i[new create edit update]

    def index
      @products = Product.order(created_at: :desc)
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
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Product updated successfully."
      else
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
      params.require(:product).permit(:name, :description, :short_description, :price, :stock, :image_url, :category_id)
    end

    def load_categories
      @categories = Category.order(:name)
    end
  end
end
