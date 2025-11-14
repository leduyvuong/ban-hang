# frozen_string_literal: true

require "securerandom"
require "bigdecimal"

class Product < ApplicationRecord
  belongs_to :shop
  belongs_to :category, optional: true
  has_one_attached :image
  has_one :product_discount, dependent: :destroy
  has_one :discount, through: :product_discount
  has_many :reviews, dependent: :destroy
  has_many :visible_reviews, -> { visible }, class_name: "Review"
  has_many :wishlist_items, dependent: :destroy

  before_validation :ensure_slug!
  before_validation :apply_currency_conversion

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_currency, presence: true
  validates :price_local_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :shop, presence: true
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

  scope :with_active_discounts, lambda {
    joins(product_discount: :discount).merge(Discount.currently_active)
  }

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

  scope :for_shop, lambda { |shop|
    where(shop_id: shop)
  }

  def self.find_by_slug_or_id!(identifier, shop: nil)
    relation = shop.present? ? where(shop_id: shop) : all

    relation.find_by!(slug: identifier)
  rescue ActiveRecord::RecordNotFound
    relation.find(identifier)
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

  def active_discount
    discount if discount&.currently_active?
  end

  def discounted_price
    active = active_discount
    return price.to_d unless active

    active.apply_to(price).round(2)
  end

  def price_in(currency_code)
    CurrencyConverter.convert(BigDecimal(price.to_s), from: CurrencyConverter.base_currency, to: currency_code)
  end

  def local_price
    price_local_amount.presence || price
  end

  def discount_amount
    (price.to_d - discounted_price).clamp(0, price.to_d)
  end

  def discount_percentage
    return 0 if price.to_d.zero?

    ((discount_amount / price.to_d) * 100).round(2)
  end

  def discount_badge_label(currency: CurrencyConverter.base_currency)
    active = active_discount
    return if active.blank?

    active.formatted_value(currency: currency)
  end

  def discounted?
    discount_amount.positive?
  end

  def average_rating
    return 0.0 if reviews_count.zero?

    visible_reviews.average(:rating).to_f.round(1)
  end

  def reviews_count
    visible_association = association(:visible_reviews)
    return visible_association.target.size if visible_association.loaded?

    visible_reviews.count
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

    relation = self.class.unscoped
    relation = relation.where(shop_id: shop_id) if shop_id.present?

    while relation.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate
  end

  def apply_currency_conversion
    return if price_currency.blank? && price_local_amount.blank?

    currency_code = price_currency.presence || CurrencyConverter.base_currency
    local_amount = price_local_amount.presence || price

    return if local_amount.blank?

    local_amount = BigDecimal(local_amount.to_s)

    converted = CurrencyConverter.convert(local_amount, from: currency_code, to: CurrencyConverter.base_currency)
    self.price = converted
    self.price_currency = currency_code.upcase
    self.price_local_amount = local_amount
  rescue CurrencyConverter::ConversionError => e
    errors.add(:base, e.message)
  end
end
