# frozen_string_literal: true

module Analytics
  class Dashboard
    CANCELLED_STATUSES = %w[cancelled refunded].freeze
    ORDER_TIMESTAMP_SQL = "COALESCE(orders.placed_at, orders.created_at)".freeze

    attr_reader :range, :target_currency

    def initialize(range: Analytics::DateRange.build, currency: CurrencyConverter.base_currency)
      @range = range
      @target_currency = currency.to_s.upcase.presence || CurrencyConverter.base_currency
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        {
          range: range.to_h,
          currency: target_currency,
          summary: summary_metrics,
          charts: chart_data,
          top_products: top_products
        }
      end
    end

    private

    def cache_key
      [
        "analytics/dashboard",
        range.start_time.to_i,
        range.end_time.to_i,
        range.interval,
        target_currency
      ]
    end

    def summary_metrics
      {
        revenue: revenue_summary,
        orders: order_summary,
        active_customers: active_customers_count,
        average_order_value: average_order_value,
        conversion_rate: conversion_rate
      }
    end

    def revenue_summary
      current_month_range = month_range(Time.zone.today)
      last_month_range = month_range(Time.zone.today.last_month)
      current_year_range = year_to_date_range

      current_month_revenue = revenue_for_range(current_month_range)
      last_month_revenue = revenue_for_range(last_month_range)
      year_to_date_revenue = revenue_for_range(current_year_range)

      {
        current_month: convert_amount(current_month_revenue),
        last_month: convert_amount(last_month_revenue),
        year_to_date: convert_amount(year_to_date_revenue),
        month_over_month_change: percent_change(current_month_revenue, last_month_revenue)
      }
    end

    def order_summary
      current_month_range = month_range(Time.zone.today)
      last_month_range = month_range(Time.zone.today.last_month)
      current_year_range = year_to_date_range

      current_month_orders = orders_for_range(current_month_range)
      last_month_orders = orders_for_range(last_month_range)
      {
        current_month: current_month_orders,
        last_month: last_month_orders,
        year_to_date: orders_for_range(current_year_range),
        month_over_month_change: percent_change(current_month_orders, last_month_orders)
      }
    end

    def active_customers_count
      window_start = range.end_time - 90.days
      count = paid_orders
              .where.not(user_id: nil)
              .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: window_start, end: range.end_time)
              .distinct.count(:user_id)
      { value: count }
    end

    def average_order_value
      orders_scope = paid_orders
                     .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: range.start_time, end: range.end_time)
      order_count = orders_scope.count
      revenue = orders_scope.sum(:total)
      average = order_count.positive? ? (revenue / order_count) : 0
      { value: convert_amount(average) }
    end

    def conversion_rate
      # Placeholder: requires visitor analytics integration. Return nil with context.
      {
        value: nil,
        note: "Conversion rate requires visitor tracking integration."
      }
    end

    def chart_data
      {
        revenue: build_series(series_revenue_query, currency: true, label: "Revenue"),
        orders: build_series(series_orders_query, currency: false, label: "Orders"),
        customers: build_series(series_customers_query, currency: false, label: "New customers")
      }
    end

    def series_revenue_query
      paid_orders
        .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: range.start_time, end: range.end_time)
        .select("DATE_TRUNC('#{bucket}', #{ORDER_TIMESTAMP_SQL}) AS period, SUM(orders.total) AS metric_value")
        .group("period")
        .order("period ASC")
    end

    def series_orders_query
      paid_orders
        .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: range.start_time, end: range.end_time)
        .select("DATE_TRUNC('#{bucket}', #{ORDER_TIMESTAMP_SQL}) AS period, COUNT(orders.id) AS metric_value")
        .group("period")
        .order("period ASC")
    end

    def series_customers_query
      User.customers
          .where("users.created_at BETWEEN :start AND :end", start: range.start_time, end: range.end_time)
          .select("DATE_TRUNC('#{bucket}', users.created_at) AS period, COUNT(users.id) AS metric_value")
          .group("period")
          .order("period ASC")
    end

    def build_series(scope, currency:, label:)
      records = scope.to_a
      labels = []
      data = []
      fill_missing_periods(records).each do |period_time, value|
        labels << format_period_label(period_time)
        data << (currency ? convert_amount(value) : value.to_f)
      end

      {
        label: label,
        labels: labels,
        data: data,
        currency: currency
      }
    end

    def fill_missing_periods(records)
      index = records.each_with_object({}) do |record, memo|
        next if record.period.blank?

        memo[truncate_time(record.period.in_time_zone)] = record.metric_value.to_f
      end

      results = []
      current = truncate_time(range.start_time)
      last = truncate_time(range.end_time)

      while current <= last
        results << [current, index.fetch(current, 0)]
        current = advance_time(current)
      end

      results
    end

    def advance_time(time)
      case bucket
      when "day"
        (time + 1.day).beginning_of_day
      when "week"
        (time + 1.week).beginning_of_week
      else
        (time + 1.month).beginning_of_month
      end
    end

    def truncate_time(time)
      case bucket
      when "day"
        time.beginning_of_day
      when "week"
        time.beginning_of_week
      else
        time.beginning_of_month
      end
    end

    def format_period_label(time)
      case bucket
      when "day"
        time.strftime("%b %-d")
      when "week"
        "Week of #{time.strftime('%b %-d')}"
      else
        time.strftime("%b %Y")
      end
    end

    def bucket
      case range.interval
      when :week
        "week"
      when :month
        "month"
      else
        "day"
      end
    end

    def top_products
      records = OrderItem
                .joins(:order)
                .joins("LEFT OUTER JOIN products ON products.id = order_items.product_id")
                .where.not(orders: { status: CANCELLED_STATUSES })
                .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: range.start_time, end: range.end_time)
                .select(
                  "products.id AS product_id, COALESCE(products.name, 'Unknown product') AS product_name, " \
                  "SUM(order_items.quantity) AS units_sold, SUM(order_items.total_price) AS revenue"
                )
                .group("products.id, product_name")
                .order("revenue DESC")
                .limit(10)
                .to_a

      grand_total = records.sum { |record| record.revenue.to_f }

      records.each_with_index.map do |record, index|
        revenue_value = record.revenue.to_f
        converted_revenue = convert_amount(revenue_value)

        {
          rank: index + 1,
          product_id: record.product_id,
          product_name: record.product_name,
          units_sold: record.units_sold.to_i,
          revenue: converted_revenue,
          revenue_share: grand_total.positive? ? (revenue_value / grand_total * 100.0) : 0.0
        }
      end
    end

    def paid_orders
      @paid_orders ||= Order.where.not(status: CANCELLED_STATUSES)
    end

    def revenue_for_range(period_range)
      paid_orders
        .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: period_range.begin, end: period_range.end)
        .sum(:total)
    end

    def orders_for_range(period_range)
      paid_orders
        .where("#{ORDER_TIMESTAMP_SQL} BETWEEN :start AND :end", start: period_range.begin, end: period_range.end)
        .count
    end

    def month_range(date)
      start_at = date.beginning_of_month.beginning_of_day
      end_at = date.end_of_month.end_of_day
      start_at..end_at
    end

    def year_to_date_range
      start_at = Time.zone.today.beginning_of_year.beginning_of_day
      end_at = Time.zone.today.end_of_day
      start_at..end_at
    end

    def percent_change(current, previous)
      previous_value = previous.to_f
      return nil if previous_value.zero?

      current_value = current.to_f
      (((current_value - previous_value) / previous_value) * 100).round(2)
    end

    def convert_amount(amount)
      CurrencyConverter.convert(amount, from: CurrencyConverter.base_currency, to: target_currency).to_f
    rescue CurrencyConverter::ConversionError
      amount.to_f
    end
  end
end
