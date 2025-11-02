# frozen_string_literal: true

return unless defined?(Rack::Attack)

class Rack::Attack
  throttle("req/ip", limit: ENV.fetch("RACK_ATTACK_LIMIT", 60).to_i, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api")
  end

  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("session", "email")&.downcase
    end
  end

  safelist("allow-localhost") do |req|
    %w[127.0.0.1 ::1].include?(req.ip)
  end
end

Rails.application.config.middleware.use Rack::Attack if Rails.env.production?
