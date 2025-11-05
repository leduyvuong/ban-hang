# frozen_string_literal: true

module Admin
  class DiscountsController < ApplicationController
    before_action :set_discount, only: %i[show edit update toggle_active]

    def index
      @discounts = Discount.order(active: :desc, start_date: :asc, name: :asc)
      @active_discounts = @discounts.select(&:currently_active?)

      set_admin_page(
        title: "Discounts",
        subtitle: "Manage coupons and promotions",
        actions: render_to_string(
          partial: "admin/shared/primary_actions",
          locals: { actions: [
            { label: "New discount", url: new_admin_discount_path, style: "primary" }
          ] }
        )
      )
    end

    def show
      redirect_to edit_admin_discount_path(@discount)
    end

    def new
      @discount = Discount.new(start_date: Time.current.beginning_of_hour)
      set_admin_page(title: "New discount", subtitle: "Create a promotional offer")
    end

    def create
      @discount = Discount.new(discount_params)

      if @discount.save
        redirect_to admin_discounts_path, notice: "Discount created successfully."
      else
        flash.now[:error] = @discount.errors.full_messages.to_sentence
        set_admin_page(title: "New discount", subtitle: "Create a promotional offer")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      set_admin_page(title: "Edit discount", subtitle: @discount.name)
    end

    def update
      if @discount.update(discount_params)
        redirect_to admin_discounts_path, notice: "Discount updated successfully."
      else
        flash.now[:error] = @discount.errors.full_messages.to_sentence
        set_admin_page(title: "Edit discount", subtitle: @discount.name)
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      @discount.update(active: !@discount.active?)
      status = @discount.active? ? "activated" : "deactivated"
      redirect_to admin_discounts_path, notice: "Discount #{status}."
    end

    private

    def set_discount
      @discount = Discount.find(params[:id])
    end

    def discount_params
      params.require(:discount).permit(
        :name,
        :discount_type,
        :value,
        :value_local_amount,
        :currency,
        :start_date,
        :end_date,
        :active
      )
    end
  end
end
