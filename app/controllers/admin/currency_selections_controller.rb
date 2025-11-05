# frozen_string_literal: true

module Admin
  class CurrencySelectionsController < ApplicationController
    def create
      currency = params.require(:currency).to_s.upcase
      if available_currencies.include?(currency)
        session[:currency] = currency
        if params[:remember].present?
          cookies.permanent[:preferred_currency] = currency
        else
          cookies.delete(:preferred_currency)
        end
        flash[:notice] = "Currency updated to #{currency}."
      else
        flash[:error] = "Unsupported currency: #{currency}."
      end

      redirect_back fallback_location: admin_root_path
    end
  end
end
