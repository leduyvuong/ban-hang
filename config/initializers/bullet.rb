# frozen_string_literal: true

if defined?(Bullet)
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = Rails.env.development?
      Bullet.alert = true
      Bullet.bullet_logger = true
      Bullet.console = true
      Bullet.rails_logger = true
    end
  end
end
