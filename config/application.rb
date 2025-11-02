# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module BanHang
  class Application < Rails::Application
    config.load_defaults 7.1

    config.generators do |g|
      g.helper false
      g.assets false
      g.test_framework :rspec, fixture: false
      g.factory_bot suffix: "_factory"
    end

    config.time_zone = "UTC"
    config.eager_load_paths << Rails.root.join("lib")
    config.autoload_paths << Rails.root.join("app/forms")
    config.autoload_paths << Rails.root.join("app/services")
    config.active_job.queue_adapter = :sidekiq
  end
end
