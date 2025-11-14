# frozen_string_literal: true

require "securerandom"

class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :shop
  has_many :order_items, dependent: :destroy

  enum status: {
    pending: "pending",
    processing: "processing",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  scope :with_status, ->(value) { statuses.key?(value) ? where(status: value) : all }
  scope :search, lambda { |term|
    return all if term.blank?

    pattern = "%#{sanitize_sql_like(term)}%"
    left_outer_joins(:user)
      .where("orders.order_number ILIKE :pattern OR users.email ILIKE :pattern OR users.name ILIKE :pattern", pattern: pattern)
      .distinct
  }

  accepts_nested_attributes_for :order_items, allow_destroy: true

  before_validation :assign_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :shop, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :total_local_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
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

  def total_in(currency_code)
    CurrencyConverter.convert(total, from: CurrencyConverter.base_currency, to: currency_code)
  end
end
