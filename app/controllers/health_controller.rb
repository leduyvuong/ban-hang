# frozen_string_literal: true

class HealthController < ActionController::API
  def show
    redis_ok = redis_alive?
    db_ok = db_alive?

    status_code = (redis_ok && db_ok) ? :ok : :service_unavailable
    render json: {
      status: (status_code == :ok ? "ok" : "degraded"),
      redis: redis_ok,
      database: db_ok
    }, status: status_code
  end

  private

  def db_alive?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis_alive?
    return true unless defined?(Sidekiq)

    Sidekiq.redis do |conn|
      conn.respond_to?(:ping) ? conn.ping == "PONG" : conn.present?
    end
  rescue StandardError
    false
  end
end
