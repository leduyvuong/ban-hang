# frozen_string_literal: true

class Feature < ApplicationRecord
  has_many :shop_features, dependent: :destroy
  has_many :shops, through: :shop_features
  has_many :audit_logs, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :by_category, ->(category) { where(category: category) }
end
