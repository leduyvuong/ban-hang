# frozen_string_literal: true

require "digest"

class User < ApplicationRecord
  has_secure_password

  enum role: { customer: 0, admin: 1 }, _default: :customer

  has_many :orders, dependent: :nullify

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  scope :with_reset_token, ->(token) { where(reset_password_token: token) }

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

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def generate_token
    SecureRandom.hex(32)
  end

  def digest_token(token)
    self.class.digest_token(token)
  end

  def secure_compare(token_a, token_b)
    return false if token_a.blank? || token_b.blank?

    ActiveSupport::SecurityUtils.secure_compare(token_a, token_b)
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
