# frozen_string_literal: true

module Admin
  class CustomersController < ApplicationController
    before_action :set_customer, only: %i[show edit update destroy block]

    def index
      @query = params[:query].to_s.strip
      @status_filter = params[:status].presence

      scope = User.customers.where(shop: current_shop)
      scope = scope.where(blocked_at: nil) if @status_filter == "active"
      scope = scope.where.not(blocked_at: nil) if @status_filter == "blocked"
      scope = scope.search(@query) if @query.present?

      stats_scope = scope.with_order_stats.order(created_at: :desc)

      @pagy, @customers = pagy(stats_scope, items: 20)
    end

    def show
      @orders = @customer.orders.where(shop: current_shop).includes(:order_items).order(created_at: :desc).to_a
      @recent_orders = @orders.first(5)
      @total_spent = @orders.sum { |order| BigDecimal(order.total.to_s) }
    end

    def edit
      @addresses_text = @customer.addresses.join("\n")
    end

    def update
      attributes = customer_params
      addresses = extract_addresses(attributes.delete(:addresses_text))
      attributes[:addresses] = addresses

      if @customer.update(attributes)
        redirect_to admin_customer_path(@customer), notice: "Customer updated successfully."
      else
        @addresses_text = addresses.join("\n")
        flash.now[:error] = @customer.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @customer == current_user
        redirect_to admin_customers_path, alert: "You cannot delete your own account."
      else
        @customer.destroy
        redirect_to admin_customers_path, notice: "Customer deleted."
      end
    end

    def block
      if @customer == current_user
        redirect_back fallback_location: admin_customers_path, alert: "You cannot block yourself."
        return
      end

      if @customer.blocked?
        @customer.update!(blocked_at: nil)
        notice = "Customer unblocked."
      else
        @customer.update!(blocked_at: Time.current)
        notice = "Customer blocked."
      end

      redirect_back fallback_location: admin_customers_path, notice: notice
    end

    private

    def set_customer
      @customer = User.customers.where(shop: current_shop).find(params[:id])
    end

    def customer_params
      params.require(:user).permit(:name, :email, :phone, :addresses_text)
    end

    def extract_addresses(value)
      value.to_s.lines.map(&:strip).reject(&:blank?)
    end
  end
end
