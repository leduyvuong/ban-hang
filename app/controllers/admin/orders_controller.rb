# frozen_string_literal: true

module Admin
  class OrdersController < ApplicationController
    before_action :set_order, only: %i[show]

    def index
      @orders = Order.order(created_at: :desc)
      set_admin_page(
        title: "Orders",
        subtitle: "Track customer orders",
        actions: render_to_string(partial: "admin/shared/primary_actions", locals: { actions: [
          { label: "Export orders", url: "#", style: "secondary" }
        ] })
      )
    end

    def show
      set_admin_page(title: "Order ##{@order.order_number}", subtitle: @order.status.capitalize)
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end
  end
end
