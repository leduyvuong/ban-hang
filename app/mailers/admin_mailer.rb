# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  default to: ENV.fetch("DEFAULT_ADMIN_EMAIL", "admin@example.com"), from: ENV.fetch("DEFAULT_MAILER_FROM", "no-reply@example.com")

  def low_stock_alert(product_id)
    @product = Product.find(product_id)
    mail subject: "Low stock alert: #{@product.name}"
  end
end
