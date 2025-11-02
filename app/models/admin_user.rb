# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_secure_password

  enum role: {
    master_admin: 0,
    shop_owner: 1,
    shop_manager: 2,
    shop_support: 3
  }, _default: :master_admin

  belongs_to :shop, optional: true

  has_many :audit_logs
  has_many :unlocked_shop_features, class_name: "ShopFeature", foreign_key: :unlocked_by_id, inverse_of: :unlocked_by, dependent: :nullify

  scope :active, -> { where(active: true) }

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :shop, presence: true, unless: :master_admin?

  before_validation :normalize_email

  def is_master_admin?
    master_admin? && shop.nil?
  end

  def is_shop_admin?
    shop.present? && (shop_owner? || shop_manager?)
  end

  def is_shop_staff?
    shop.present? && shop_support?
  end

  def can_manage_features?
    is_master_admin?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
