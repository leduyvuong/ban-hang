# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      reject_unauthorized_connection unless current_user
    end

    private

    def find_verified_user
      user_id = request.session[:user_id]
      user = User.find_by(id: user_id) if user_id
      return user if user

      remember_user_id = cookies.encrypted[:remember_user_id]
      remember_token = cookies.signed[:remember_token]

      return nil if remember_user_id.blank? || remember_token.blank?

      user = User.find_by(id: remember_user_id)
      return user if user&.remember_token_authenticated?(remember_token)

      nil
    end
  end
end
