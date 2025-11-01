# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.js_compressor = :uglifier if defined?(Uglifier)

  config.log_level = :info
  config.log_tags = [:request_id]

  config.cache_store = :mem_cache_store

  config.active_storage.service = :local

  config.force_ssl = false

  config.log_formatter = ::Logger::Formatter.new
  config.active_support.report_deprecations = false

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false

  config.i18n.fallbacks = true

  config.active_record.dump_schema_after_migration = false
end
