# frozen_string_literal: true

class CheckoutController < ApplicationController
  before_action :require_login!
  before_action :ensure_cart_present

  def show
    current_cart.preload_products
    @shipping_form = Checkout::ShippingForm.from_session(session[:checkout_shipping])
    @step = ensure_step(params[:step])
    @step = 1 if @step > 1 && session[:checkout_shipping].blank?
    @order_complete = ActiveModel::Type::Boolean.new.cast(params[:complete])

    set_page_metadata(
      title: "Checkout",
      description: "Securely complete your BanHang order with our streamlined checkout experience.",
      canonical: checkout_url,
      robots: "noindex"
    )
  end

  def update
    case params[:step]
    when "shipping"
      handle_shipping_step
    when "review"
      handle_review_step
    when "payment"
      handle_payment_step
    else
      render_step(1)
    end
  end

  private

  def handle_shipping_step
    @shipping_form = Checkout::ShippingForm.new(shipping_params)
    if @shipping_form.valid?
      session[:checkout_shipping] = @shipping_form.to_h
      render_step(2, shipping_form: @shipping_form)
    else
      render_step(1, shipping_form: @shipping_form)
    end
  end

  def handle_review_step
    return render_step(1) if session[:checkout_shipping].blank?

    render_step(3)
  end

  def handle_payment_step
    return render_step(1) if session[:checkout_shipping].blank?

    render_step(3, order_complete: true)
  end

  def render_step(step, shipping_form: nil, order_complete: false)
    current_cart.preload_products
    shipping_form ||= Checkout::ShippingForm.from_session(session[:checkout_shipping])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "checkout_steps",
          partial: "checkout/step",
          locals: {
            step: step,
            shipping_form: shipping_form,
            order_complete: order_complete
          }
        )
      end

      format.html do
        redirect_to checkout_path(step: step, complete: order_complete)
      end
    end
  end

  def ensure_step(value)
    step = value.to_i
    step = 1 if step < 1 || step > 3
    step
  end

  def shipping_params
    params.require(:shipping).permit(:name, :address, :city, :postal_code, :phone)
  end

  def ensure_cart_present
    return unless current_cart.empty?

    redirect_to products_path, alert: "Add items to your cart before checking out."
  end
end
