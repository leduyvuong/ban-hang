# frozen_string_literal: true

class OrderConfirmationJob < ApplicationJob
  queue_as :mailers

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(order_id)
    order = Order.find(order_id)
    OrderMailer.with(email: order.user&.email).confirmation(order.id).deliver_now
  end
end
