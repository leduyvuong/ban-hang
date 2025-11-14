# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :shop
  has_many :products, dependent: :nullify

  before_validation :generate_slug

  validates :name, presence: true, uniqueness: { scope: :shop_id, case_sensitive: false }, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: { scope: :shop_id, case_sensitive: false }
  validates :shop, presence: true

  scope :for_shop, ->(shop) { where(shop_id: shop) }

  private

  def generate_slug
    return if name.blank?

    base = name.parameterize
    candidate = base
    counter = 2

    relation = shop_id.present? ? self.class.where(shop_id: shop_id) : self.class.all

    while relation.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
