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
      g.test_framework :test_unit, fixture: false
    end

    config.time_zone = "UTC"
    config.eager_load_paths << Rails.root.join("lib")
  end
end
