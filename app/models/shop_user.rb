# frozen_string_literal: true

class ShopUser < ApplicationRecord
  ROLES = %w[staff manager].freeze

  belongs_to :shop
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :shop_id }
end
