# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      @products_count = Product.count
      @orders_count = Order.count if defined?(Order)
      @recent_products = Product.includes(:discount).order(created_at: :desc).limit(5)
      @active_discounts = Discount.currently_active.order(Arel.sql("COALESCE(end_date, '9999-12-31') ASC"))
      @upcoming_discounts = Discount.active.where("start_date > ?", Time.current).order(:start_date)

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
