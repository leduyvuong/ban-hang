# frozen_string_literal: true

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price_local, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price_local, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validate :product_has_stock

  private

  def product_has_stock
    return if product.blank?

    if product.stock.to_i < quantity
      errors.add(:quantity, "exceeds available stock (#{product.stock} remaining)")
    end
  end
end
