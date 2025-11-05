# frozen_string_literal: true

module Analytics
  class DateRange
    PRESETS = {
      "last_7_days" => { label: "Last 7 days", duration: 7.days },
      "last_30_days" => { label: "Last 30 days", duration: 30.days },
      "last_90_days" => { label: "Last 90 days", duration: 90.days },
      "year_to_date" => { label: "Year to date", duration: nil }
    }.freeze

    attr_reader :start_time, :end_time, :preset, :label

    def self.build(params = {})
      new(params)
    end

    def initialize(params = {})
      @preset = (params[:range].presence || "last_30_days").to_s
      assign_range(params)
    end

    def interval
      return :month if duration_in_days > 180
      return :week if duration_in_days > 31

      :day
    end

    def duration_in_days
      ((end_time.to_date - start_time.to_date).to_i + 1).clamp(1, 10_000)
    end

    def to_h
      {
        start: start_time.iso8601,
        end: end_time.iso8601,
        preset: preset,
        label: label,
        interval: interval,
        days: duration_in_days
      }
    end

    private

    def assign_range(params)
      case preset
      when "custom"
        build_custom_range(params)
      when "year_to_date"
        start_date = Time.zone.today.beginning_of_year
        end_date = Time.zone.today
        set_values(start_date.beginning_of_day, end_date.end_of_day, PRESETS.fetch(preset)[:label])
      else
        config = PRESETS.fetch(preset, PRESETS["last_30_days"])
        end_date = Time.zone.today
        start_date = end_date - config[:duration]
        set_values(start_date.beginning_of_day, end_date.end_of_day, config[:label])
      end
    end

    def build_custom_range(params)
      start_param = parse_date(params[:start_date]) || 30.days.ago.to_date
      end_param = parse_date(params[:end_date]) || Time.zone.today
      if end_param < start_param
        start_param, end_param = end_param, start_param
      end

      set_values(start_param.beginning_of_day, end_param.end_of_day, "Custom range")
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def set_values(start_at, end_at, friendly_label)
      @start_time = start_at
      @end_time = end_at
      @label = friendly_label
    end
  end
end
