# frozen_string_literal: true

require "securerandom"

class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy

  enum status: {
    pending: "pending",
    processing: "processing",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  accepts_nested_attributes_for :order_items, allow_destroy: true

  before_validation :assign_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validate :ensure_items_in_stock, on: :create

  private

  def assign_order_number
    return if order_number.present?

    self.order_number = "BH#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(3).upcase}"
  end

  def ensure_items_in_stock
    order_items.each do |item|
      next if item.product.blank?

      if item.quantity > item.product.stock.to_i
        errors.add(:base, "Not enough stock for #{item.product.name}. Only #{item.product.stock} left.")
      end
    end
  end
end
