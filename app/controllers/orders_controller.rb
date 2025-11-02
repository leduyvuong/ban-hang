# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :require_login!
  before_action :set_order, only: %i[show]

  def index
    @orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
  end

  def show; end

  private

  def set_order
    @order = current_user.orders.includes(order_items: :product).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "Order not found."
  end
end
