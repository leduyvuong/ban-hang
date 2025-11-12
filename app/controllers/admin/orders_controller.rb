# frozen_string_literal: true

module Admin
  class OrdersController < ApplicationController
    before_action :set_order, only: %i[show]

    def index
      @query = params[:query].to_s.strip
      @status_filter = params[:status].presence

      scope = Order.includes(:user).where(shop: current_shop).order(created_at: :desc)
      scope = scope.search(@query) if @query.present?
      scope = scope.with_status(@status_filter) if @status_filter.present?

      @pagy, @orders = pagy(scope, items: 20)
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
      @order = Order.where(shop: current_shop).find(params[:id])
    end
  end
end
