# frozen_string_literal: true

class LowStockAlertJob < ApplicationJob
  queue_as :low_priority

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product && product.stock < 5

    AdminMailer.low_stock_alert(product.id).deliver_now
  end
end
