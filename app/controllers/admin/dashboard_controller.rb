# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      @products_count = Product.count
      @orders_count = Order.count if defined?(Order)
      @recent_products = Product.order(created_at: :desc).limit(5)

      set_admin_page(
        title: "Dashboard",
        subtitle: "Snapshot of store activity",
        actions: render_to_string(partial: "admin/shared/primary_actions", locals: { actions: [
          { label: "Add product", url: new_admin_product_path, style: "primary" }
        ] })
      )
    end
  end
end
