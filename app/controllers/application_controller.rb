# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  protect_from_forgery with: :exception

  helper_method :current_cart, :current_user, :logged_in?, :admin?
  helper_method :current_currency, :available_currencies

  before_action :assign_current_currency

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from StandardError, with: :handle_internal_error unless Rails.env.development?

  private

  def handle_not_found(exception)
    Rails.logger.warn("[404] #{exception.class}: #{exception.message}")
    respond_with_error("We couldn't find what you were looking for.", status: :not_found)
  end

  def handle_internal_error(exception)
    Rails.logger.error("[500] #{exception.class}: #{exception.message}\nParams: #{request.filtered_parameters.inspect}\n#{exception.backtrace&.first(5)&.join("\n")}")
    respond_with_error("Something went wrong on our side. Please try again.", status: :internal_server_error)
  end

  def respond_with_error(message, status:, redirect: root_path)
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_back fallback_location: redirect, status: :see_other
      end
      format.turbo_stream do
        flash[:error] = message
        redirect_back fallback_location: redirect, status: :see_other
      end
      format.json do
        render json: { success: false, error: message }, status: status
      end
    end
  end

  def set_page_metadata(title: nil, description: nil, canonical: nil, robots: nil)
    @page_title = title if title.present?
    @page_description = description if description.present?
    @canonical_url = canonical if canonical.present?
    @meta_robots = robots if robots.present?
  end

  def current_user
    return @current_user if defined?(@current_user)

    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    elsif cookies.encrypted[:remember_user_id] && cookies.signed[:remember_token]
      user = User.find_by(id: cookies.encrypted[:remember_user_id])
      if user&.remember_token_authenticated?(cookies.signed[:remember_token])
        log_in(user)
        @current_user = user
      end
    end

    @current_user ||= nil
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def require_login!
    return if logged_in?

    store_location
    flash[:error] = "Please log in to continue."
    redirect_to new_session_path
  end

  def require_admin!
    return if admin?

    flash[:error] = "You are not authorized to access that page."
    redirect_to root_path
  end

  def current_cart
    return @current_cart if defined?(@current_cart)

    cart = Cart.from_session(session[:cart])

    if logged_in? && cart.empty?
      cart = Cart.from_user(current_user)
      session[:cart] = cart.serialize
    end

    @current_cart = cart
  end

  def persist_cart!
    session[:cart] = current_cart.serialize
    current_user&.update_cart!(current_cart)
  end

  def log_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  def log_out
    forget(current_user) if current_user
    session.delete(:user_id)
    @current_user = nil
  end

  def remember(user)
    token = user.remember!
    cookies.encrypted[:remember_user_id] = { value: user.id, expires: 30.days.from_now }
    cookies.signed[:remember_token] = { value: token, expires: 30.days.from_now }
  end

  def forget(user)
    user&.forget!
    cookies.delete(:remember_user_id)
    cookies.delete(:remember_token)
  end

  def merge_cart!(user)
    return unless user

    user_cart = Cart.from_user(user)
    session_cart = Cart.from_session(session[:cart])

    begin
      user_cart.merge!(session_cart)
    rescue Cart::OutOfStockError => e
      flash[:error] = e.message
    end

    user.update_cart!(user_cart)
    session[:cart] = user_cart.serialize
    @current_cart = user_cart
  end

  def store_location
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  def redirect_back_or(default)
    redirect_to(session.delete(:return_to) || default)
  end

  def assign_current_currency
    requested_currency = params[:currency].presence ||
      session[:currency].presence ||
      cookies[:preferred_currency].presence

    if requested_currency.present?
      code = requested_currency.to_s.upcase
      if available_currencies.include?(code)
        session[:currency] = code
        @current_currency = code
      end
    end

    @current_currency ||= CurrencyRate::BASE_CURRENCY
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
    @current_currency = CurrencyRate::BASE_CURRENCY
  end

  def current_currency
    @current_currency || CurrencyRate::BASE_CURRENCY
  end

  def available_currencies
    @available_currencies ||= CurrencyRate.available_codes
  rescue ActiveRecord::StatementInvalid
    CurrencyRate::SUPPORTED_CURRENCIES.keys
  end
end
