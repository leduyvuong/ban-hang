# frozen_string_literal: true
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_cart, :current_user, :logged_in?, :admin?

  private

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
    redirect_to new_session_path, alert: "Please log in to continue."
  end

  def require_admin!
    return if admin?

    redirect_to root_path, alert: "You are not authorized to access that page."
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

    user_cart.merge!(session_cart)
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
end
