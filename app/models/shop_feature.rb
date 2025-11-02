# frozen_string_literal: true

class ShopFeature < ApplicationRecord
  enum status: { locked: 0, unlocked: 1 }

  belongs_to :shop
  belongs_to :feature
  belongs_to :unlocked_by, class_name: "AdminUser", optional: true

  validates :shop_id, :feature_id, presence: true
  validates :shop_id, uniqueness: { scope: :feature_id }
end
