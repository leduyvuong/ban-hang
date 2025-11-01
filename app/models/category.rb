# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :products, dependent: :nullify

  before_validation :generate_slug

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  private

  def generate_slug
    return if name.blank?

    base = name.parameterize
    candidate = base
    counter = 2

    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
