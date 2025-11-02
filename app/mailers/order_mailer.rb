# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  default from: ENV.fetch("DEFAULT_MAILER_FROM", "no-reply@example.com")

  def confirmation(order_id)
    @order = Order.includes(order_items: :product).find(order_id)
    mail to: recipient_email, subject: "Your BanHang order ##{@order.order_number}"
  end

  private

  def recipient_email
    return params[:email] if params[:email].present?

    @order.user&.email || ENV.fetch("DEFAULT_ADMIN_EMAIL", "admin@example.com")
  end
end
