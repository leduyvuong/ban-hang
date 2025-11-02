# frozen_string_literal: true

class AuditLog < ApplicationRecord
  ACTIONS = %w[unlock lock].freeze

  belongs_to :admin_user
  belongs_to :shop
  belongs_to :feature

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :reason, length: { maximum: 500 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_shop, ->(shop) { where(shop: shop) }
  scope :for_feature, ->(feature) { where(feature: feature) }
  scope :by_action, ->(action) { where(action: action) }
end
