# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "active_job/test_helper"
require "factory_bot_rails"
require "faker"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper

  config.before do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
