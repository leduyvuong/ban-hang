# frozen_string_literal: true

module Admin
  class CurrencyRatesController < ApplicationController
    before_action :set_currency_rate, only: %i[edit update]
    before_action :ensure_master_admin!

    def index
      @currency_rates = CurrencyRate.ordered
      @base_currency = CurrencyRate::BASE_CURRENCY
      set_admin_page(title: "Currency rates", subtitle: "Manage exchange rates for reporting")
    end

    def new
      @currency_rate = CurrencyRate.new
      set_admin_page(title: "New currency", subtitle: "Add an exchange rate")
    end

    def create
      @currency_rate = CurrencyRate.new(currency_rate_params)
      if @currency_rate.save
        redirect_to admin_currency_rates_path, notice: "Currency rate saved."
      else
        flash.now[:error] = @currency_rate.errors.full_messages.to_sentence
        set_admin_page(title: "New currency", subtitle: "Add an exchange rate")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      set_admin_page(title: "Edit currency", subtitle: @currency_rate.currency_code)
    end

    def update
      if @currency_rate.update(currency_rate_params)
        redirect_to admin_currency_rates_path, notice: "Currency rate updated."
      else
        flash.now[:error] = @currency_rate.errors.full_messages.to_sentence
        set_admin_page(title: "Edit currency", subtitle: @currency_rate.currency_code)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_currency_rate
      @currency_rate = CurrencyRate.find(params[:id])
    end

    def currency_rate_params
      params.require(:currency_rate).permit(:currency_code, :rate_to_base, :fetched_at, :source)
            .merge(base_currency: CurrencyRate::BASE_CURRENCY)
    end
  end
end
