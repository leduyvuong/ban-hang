# frozen_string_literal: true

require "digest"

class User < ApplicationRecord
  has_secure_password

  enum role: { customer: 0, shop_owner: 1, admin: 2 }, _default: :customer

  has_one :owned_shop, class_name: "Shop", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  belongs_to :shop, optional: true
  has_many :shop_memberships, class_name: "ShopUser", dependent: :destroy
  has_many :shops, through: :shop_memberships
  has_many :orders, dependent: :nullify
  has_many :conversation_participants, dependent: :destroy, inverse_of: :user
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlist_products, through: :wishlist_items, source: :product

  before_validation :normalize_email
  before_save :sanitize_addresses

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :phone, length: { maximum: 30 }, allow_blank: true

  scope :with_reset_token, ->(token) { where(reset_password_token: token) }
  scope :customers, -> { where(role: roles[:customer]) }
  scope :for_shop, lambda { |shop|
    joins(:shop_memberships).where(shop_users: { shop_id: shop }).distinct
  }
  scope :search, lambda { |term|
    return all if term.blank?

    pattern = "%#{sanitize_sql_like(term)}%"
    where("users.name ILIKE :pattern OR users.email ILIKE :pattern", pattern: pattern)
  }
  scope :with_order_stats, lambda {
    left_joins(:orders)
      .select(<<~SQL.squish)
        users.*,
        COUNT(orders.id) AS orders_count,
        COALESCE(SUM(orders.total), 0) AS total_spent
      SQL
      .group("users.id")
  }

  def remember!(expires_in: 30.days)
    token = generate_token
    update!(
      remember_token: digest_token(token),
      remember_token_expires_at: Time.current + expires_in
    )
    token
  end

  def forget!
    update!(remember_token: nil, remember_token_expires_at: nil)
  end

  def remember_token_authenticated?(token)
    return false if remember_token.blank? || remember_token_expires_at.blank?
    return false if remember_token_expires_at.past?

    secure_compare(remember_token, digest_token(token))
  end

  def generate_password_reset!
    raw = generate_token
    update!(
      reset_password_token: digest_token(raw),
      reset_password_sent_at: Time.current
    )
    raw
  end

  def clear_password_reset!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  def reset_token_authenticated?(token)
    return false if reset_password_token.blank?

    secure_compare(reset_password_token, digest_token(token))
  end

  def cart_items
    Array(cart_data).map(&:with_indifferent_access)
  end

  def update_cart!(cart)
    update!(cart_data: cart.serialize)
  end

  def password_reset_expired?
    reset_password_sent_at.present? && reset_password_sent_at < 2.hours.ago
  end

  def blocked?
    blocked_at.present?
  end

  def can_access_feature?(feature_slug, shop: nil)
    target_shop = shop || owned_shop || shops.first
    return true if target_shop.blank?

    target_shop.feature_unlocked?(feature_slug)
  end

  def orders_count
    return orders.length if orders.loaded?

    if has_attribute?(:orders_count)
      self[:orders_count].to_i
    else
      orders.count
    end
  end

  def total_spent
    if orders.loaded?
      return orders.sum { |order| BigDecimal(order.total.to_s) }
    end

    if has_attribute?(:total_spent)
      BigDecimal(self[:total_spent].to_s)
    else
      orders.sum(:total)
    end
  end

  def addresses
    Array(self[:addresses]).map(&:to_s)
  end

  def addresses=(value)
    super(Array(value))
  end

  def reviewed_product?(product)
    return false if product.blank?

    reviews.exists?(product: product)
  end

  def review_for(product)
    reviews.find_by(product: product)
  end

  def wishlisted_product?(product)
    return false if product.blank?

    wishlist_products.exists?(product.id)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def sanitize_addresses
    self.addresses = addresses.map(&:to_s).map(&:strip).reject(&:blank?)
  end

  def generate_token
    SecureRandom.hex(32)
  end

  def digest_token(token)
    self.class.digest_token(token)
  end

  def secure_compare(token_a, token_b)
    return false if token_a.blank? || token_b.blank?

    begin
      ActiveSupport::SecurityUtils.secure_compare(token_a.to_s, token_b.to_s)
    rescue StandardError => e
      Rails.logger.error("Token comparison error: #{e.message}")
      false
    end
  end

  class << self
    def digest_token(token)
      Digest::SHA256.hexdigest(token.to_s)
    end

    def find_by_reset_token(token)
      return nil if token.blank?

      find_by(reset_password_token: digest_token(token))
    end
  end
end
