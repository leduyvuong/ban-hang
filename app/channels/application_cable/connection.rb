# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      
      if current_user
        logger.info "Action Cable connected for user: #{current_user.id}"
      else
        logger.warn "Action Cable rejected - no user found"
        reject_unauthorized_connection
      end
    end

    private

    def find_verified_user
      # Method 1: Try to get user_id from Rack session via env
      if env["rack.session"].present? && env["rack.session"]["user_id"]
        user_id = env["rack.session"]["user_id"]
        user = User.find_by(id: user_id)
        return user if user
      end
      
      # Method 2: Try to get user_id from encrypted session cookie
      session_key = Rails.application.config.session_options[:key] || "_ban_hang_session"
      
      if (session_data = cookies.encrypted[session_key])
        user_id = session_data["user_id"] || session_data[:user_id]
        
        if user_id
          user = User.find_by(id: user_id)
          return user if user
        end
      end

      # Method 3: Fallback to remember token
      remember_user_id = cookies.encrypted[:remember_user_id]
      remember_token = cookies.signed[:remember_token]

      return nil if remember_user_id.blank? || remember_token.blank?

      user = User.find_by(id: remember_user_id)
      return user if user&.remember_token_authenticated?(remember_token)
      
      nil
    end
  end
end
