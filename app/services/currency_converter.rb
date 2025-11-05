# frozen_string_literal: true

require "bigdecimal"

class CurrencyConverter
  ConversionError = Class.new(StandardError)

  class << self
    def convert(amount, from:, to:)
      return BigDecimal("0") if amount.blank?

      from_code = normalize(from)
      to_code = normalize(to)
      numeric_amount = BigDecimal(amount.to_s)

      return numeric_amount if from_code == to_code

      base_amount = to_base(numeric_amount, from_code)
      from_base(base_amount, to_code)
    rescue ActiveRecord::RecordNotFound => e
      raise ConversionError, e.message
    end

    def to_base(amount, currency_code)
      return amount if normalize(currency_code) == base_currency

      rate = CurrencyRate.fetch_rate(currency_code)
      amount * BigDecimal(rate.rate_to_base.to_s)
    end

    def from_base(amount, currency_code)
      return amount if normalize(currency_code) == base_currency

      rate = CurrencyRate.fetch_rate(currency_code)
      divisor = BigDecimal(rate.rate_to_base.to_s)
      raise ConversionError, "Invalid exchange rate for #{currency_code}" if divisor.zero?

      amount / divisor
    end

    def base_currency
      CurrencyRate::BASE_CURRENCY
    end

    def normalize(code)
      code.to_s.upcase.presence || base_currency
    end
  end
end
