# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}",
    "Surrogate-Control" => "public, max-age=#{1.month.to_i}"
  }
  config.assets.js_compressor = :uglifier if defined?(Uglifier)

  config.log_level = :info
  config.log_tags = [:request_id]

  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    namespace: "banhang:cache"
  }
  config.action_controller.perform_caching = true

  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", :local).to_sym

  config.force_ssl = ENV["FORCE_SSL"].present?

  config.log_formatter = ::Logger::Formatter.new
  config.active_support.report_deprecations = false

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "example.com"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }
  config.action_mailer.default_options = { from: ENV.fetch("DEFAULT_MAILER_FROM", "no-reply@example.com") }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS", "smtp.sendgrid.net"),
    port: ENV.fetch("SMTP_PORT", 587),
    domain: ENV.fetch("SMTP_DOMAIN", "example.com"),
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true

  config.active_record.dump_schema_after_migration = false
  config.after_initialize do
    Rails.application.routes.default_url_options = config.action_mailer.default_url_options
  end
end
