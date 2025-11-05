# frozen_string_literal: true

module Admin
  class AnalyticsController < ApplicationController
    before_action :set_page_header

    def index
      @date_range = Analytics::DateRange.build(range_params)
      dashboard = Analytics::Dashboard.new(range: @date_range, currency: current_currency).call

      respond_to do |format|
        format.html do
          @initial_payload = dashboard
        end
        format.json do
          render json: dashboard
        end
      end
    end

    private

    def set_page_header
      set_admin_page(
        title: "Analytics Dashboard",
        subtitle: "Track revenue, orders, and customer growth"
      )
    end

    def range_params
      params.permit(:range, :start_date, :end_date)
    end
  end
end
