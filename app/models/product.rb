# frozen_string_literal: true

require "securerandom"

class Product < ApplicationRecord
  belongs_to :category, optional: true
  before_validation :ensure_slug!

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :short_description, length: { maximum: 180 }, allow_blank: true

  def self.find_by_slug_or_id!(identifier)
    find_by!(slug: identifier)
  rescue ActiveRecord::RecordNotFound
    find(identifier)
  end

  def to_param
    slug.presence || super
  end

  private

  def ensure_slug!
    return if name.blank?
    return unless slug.blank? || will_save_change_to_name?

    self.slug = unique_slug_for(name)
  end

  def unique_slug_for(value)
    base_slug = value.parameterize
    base_slug = "#{base_slug}-#{SecureRandom.hex(2)}" if base_slug.blank?

    candidate = base_slug
    counter = 2

    while self.class.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate
  end
end
