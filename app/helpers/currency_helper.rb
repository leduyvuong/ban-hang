# frozen_string_literal: true

require "bigdecimal"

module CurrencyHelper
  def available_currencies
    CurrencyRate.available_codes
  rescue ActiveRecord::StatementInvalid
    CurrencyRate::SUPPORTED_CURRENCIES.keys
  end

  def current_currency
    @current_currency || CurrencyRate::BASE_CURRENCY
  end

  def currency_symbol(code = current_currency)
    rate = CurrencyRate.fetch_rate(code)
    CurrencyRate::SUPPORTED_CURRENCIES[rate.currency_code]&.dig(:symbol) || rate.currency_code
  rescue CurrencyConverter::ConversionError, ActiveRecord::RecordNotFound
    code
  end

  def format_money(amount, currency: current_currency, precision: nil)
    return "—" if amount.blank?

    resolved_currency = currency || CurrencyConverter.base_currency
    resolved_precision = precision.nil? ? currency_precision(resolved_currency) : precision

    value = CurrencyConverter.convert(BigDecimal(amount.to_s), from: CurrencyConverter.base_currency, to: resolved_currency)
    number_to_currency(value, unit: currency_symbol(resolved_currency), format: "%u %n", precision: resolved_precision)
  rescue CurrencyConverter::ConversionError => e
    Rails.logger.warn("Currency conversion failed: #{e.message}")
    number_to_currency(amount, unit: currency_symbol(CurrencyConverter.base_currency), format: "%u %n", precision: resolved_precision || 2)
  end

  def format_money_from(amount, from_currency:, to_currency: current_currency, precision: nil)
    return "—" if amount.blank?

    resolved_to_currency = to_currency || CurrencyConverter.base_currency
    resolved_precision = precision.nil? ? currency_precision(resolved_to_currency) : precision

    value = CurrencyConverter.convert(BigDecimal(amount.to_s), from: from_currency, to: resolved_to_currency)
    number_to_currency(value, unit: currency_symbol(resolved_to_currency), format: "%u %n", precision: resolved_precision)
  rescue CurrencyConverter::ConversionError => e
    Rails.logger.warn("Currency conversion failed: #{e.message}")
    number_to_currency(amount, unit: currency_symbol(from_currency), format: "%u %n", precision: resolved_precision || 2)
  end

  private

  def currency_precision(code)
    code.to_s.upcase == "VND" ? 0 : 2
  end
end
