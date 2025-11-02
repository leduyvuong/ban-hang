# frozen_string_literal: true

require "securerandom"

class Product < ApplicationRecord
  belongs_to :category, optional: true
  has_one_attached :image

  before_validation :ensure_slug!

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :short_description, length: { maximum: 180 }, allow_blank: true
  validate :acceptable_image

  SORT_MAPPINGS = {
    "newest" => { created_at: :desc },
    "price_low_high" => { price: :asc },
    "price_high_low" => { price: :desc },
    "name_az" => { name: :asc }
  }.freeze

  scope :matching_query, ->(query) do
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where("products.name ILIKE :pattern OR products.description ILIKE :pattern", pattern: pattern)
  end

  scope :with_category_slug, ->(slug) do
    next all if slug.blank?

    joins(:category).where(categories: { slug: slug })
  end

  scope :with_min_price, ->(amount) do
    next all if amount.blank?

    where(arel_table[:price].gteq(amount))
  end

  scope :with_max_price, ->(amount) do
    next all if amount.blank?

    where(arel_table[:price].lteq(amount))
  end

  scope :with_stock_status, ->(status) do
    case status
    when "in_stock"
      where(arel_table[:stock].gt(0))
    when "out_of_stock"
      where(arel_table[:stock].lteq(0))
    else
      all
    end
  end

  scope :ordered_by_param, ->(sort_key) do
    order_clause = SORT_MAPPINGS.fetch(sort_key.presence || "newest", SORT_MAPPINGS["newest"])
    order(order_clause)
  end

  def self.find_by_slug_or_id!(identifier)
    find_by!(slug: identifier)
  rescue ActiveRecord::RecordNotFound
    find(identifier)
  end

  def to_param
    slug.presence || super
  end

  def thumbnail(width: 520, height: 320)
    image_variant(width: width, height: height)
  end

  def image_variant(width:, height:)
    return unless image.attached?

    image.variant(resize_to_fill: [width, height], saver: { quality: 85 }).processed
  end

  def acceptable_image
    return unless image.attached?

    unless image.content_type.in?(%w[image/png image/jpeg image/jpg image/webp])
      errors.add(:image, "must be a PNG, JPG, or WEBP file")
    end

    if image.byte_size > 5.megabytes
      errors.add(:image, "must be smaller than 5MB")
    end
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
