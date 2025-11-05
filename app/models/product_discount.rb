# frozen_string_literal: true

class ProductDiscount < ApplicationRecord
  belongs_to :product, touch: true
  belongs_to :discount

  validates :product_id, uniqueness: true
  validate :discount_is_active

  private

  def discount_is_active
    return if discount.blank?

    errors.add(:discount, "must be marked active to assign") unless discount.active?
  end
end
