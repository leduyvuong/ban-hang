# frozen_string_literal: true

class CurrencyRate < ApplicationRecord
  BASE_CURRENCY = "USD"
  SUPPORTED_CURRENCIES = {
    "USD" => { name: "US Dollar", symbol: "🌐 USD" },
    "EUR" => { name: "Euro", symbol: "€" },
    "VND" => { name: "Vietnamese Dong", symbol: "₫" }
  }.freeze

  before_validation :normalize_currency_code

  validates :currency_code, presence: true, uniqueness: true
  validates :base_currency, presence: true
  validates :rate_to_base, numericality: { greater_than: 0 }

  scope :ordered, -> { order(currency_code: :asc) }

  def self.fetch_rate(code)
    normalized = code.to_s.upcase.presence || BASE_CURRENCY
    return base_rate if normalized == BASE_CURRENCY

    find_by(currency_code: normalized) || raise(ActiveRecord::RecordNotFound, "Missing currency rate for #{normalized}")
  end

  def self.base_rate
    @base_rate ||= new(currency_code: BASE_CURRENCY, base_currency: BASE_CURRENCY, rate_to_base: 1)
  end

  def self.available_codes
    (SUPPORTED_CURRENCIES.keys + pluck(:currency_code)).uniq.sort
  end

  def symbol
    (SUPPORTED_CURRENCIES[currency_code]&.dig(:symbol)).presence || currency_code
  end

  def label
    info = SUPPORTED_CURRENCIES[currency_code]
    info ? "#{info[:name]} (#{currency_code})" : currency_code
  end

  private

  def normalize_currency_code
    self.currency_code = currency_code.to_s.upcase
    self.base_currency = base_currency.to_s.upcase.presence || BASE_CURRENCY
  end
end
