# frozen_string_literal: true

require "bigdecimal"

class Discount < ApplicationRecord
  enum discount_type: { percentage: 0, fixed_amount: 1 }

  has_many :product_discounts, dependent: :destroy
  has_many :products, through: :product_discounts

  validates :name, presence: true
  validates :discount_type, presence: true
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, if: :fixed_amount?
  validates :value_local_amount, numericality: { greater_than_or_equal_to: 0 }, if: :fixed_amount?
  validate :validate_value_by_type
  validate :validate_date_range

  before_validation :apply_currency_conversion, if: :fixed_amount?

  scope :active, -> { where(active: true) }
  scope :currently_active, lambda {
    now = Time.current
    active.where("(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)", now, now)
  }

  def currently_active?
    active? && within_schedule?
  end

  def applies_to?(product)
    return false unless product

    currently_active?
  end

  def apply_to(amount)
    return amount unless currently_active?

    case discount_type.to_sym
    when :percentage
      apply_percentage(amount)
    when :fixed_amount
      apply_fixed_amount(amount)
    else
      amount
    end
  end

  def formatted_value(currency: CurrencyConverter.base_currency)
    case discount_type.to_sym
    when :percentage
      precision = value.to_d.frac.zero? ? 0 : 2
      "#{ActionController::Base.helpers.number_to_percentage(value.to_f, precision: precision)} OFF"
    when :fixed_amount
      target_currency = currency || CurrencyConverter.base_currency
      display_value = CurrencyConverter.convert(value, from: CurrencyConverter.base_currency, to: target_currency)
      unit = CurrencyRate.fetch_rate(target_currency).symbol
      formatted = ActionController::Base.helpers.number_to_currency(display_value, unit: unit, format: "%u %n")
      "Save #{formatted}"
    end
  end

  def value_in_base
    fixed_amount? ? value.to_d : nil
  end

  def value_in(currency_code)
    return value unless fixed_amount?

    CurrencyConverter.convert(value, from: CurrencyConverter.base_currency, to: currency_code)
  end

  private

  def apply_percentage(amount)
    percentage_value = value.to_d / 100
    discounted = amount.to_d * (1 - percentage_value)
    discounted < 0 ? 0.to_d : discounted
  end

  def apply_fixed_amount(amount)
    discounted = amount.to_d - value.to_d
    discounted < 0 ? 0.to_d : discounted
  end

  def within_schedule?
    now = Time.current
    (start_date.blank? || start_date <= now) && (end_date.blank? || end_date >= now)
  end

  def validate_value_by_type
    return if value.blank?

    case discount_type.to_sym
    when :percentage
      errors.add(:value, "must be between 0 and 100 for percentage discounts") unless value.to_d.between?(0.01, 100)
    when :fixed_amount
      errors.add(:value, "must be greater than 0") unless value.to_d.positive?
    end
  end

  def validate_date_range
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end

  def apply_currency_conversion
    local_currency = currency.presence || CurrencyConverter.base_currency
    local_value = value_local_amount.presence || value
    return if local_value.blank?

    local_value = BigDecimal(local_value.to_s)
    converted = CurrencyConverter.convert(local_value, from: local_currency, to: CurrencyConverter.base_currency)
    self.value = converted
    self.currency = local_currency.upcase
    self.value_local_amount = local_value
  rescue CurrencyConverter::ConversionError => e
    errors.add(:base, e.message)
  end
end
