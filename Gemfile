source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.3"

# Rails framework and essential gems for the storefront

gem "rails", "~> 7.1.3"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "turbo-rails"
gem "stimulus-rails"
gem "importmap-rails"
gem "sprockets-rails"
gem "jbuilder"
gem "tailwindcss-rails", "~> 2.0"
gem "bootsnap", require: false
gem "bcrypt", "~> 3.1"
gem "pagy", "~> 6.4"
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.3"
gem "rack-attack", "~> 6.7"
gem "sentry-rails", "~> 5.15"
gem "dotenv-rails", groups: %i[development test]
gem "image_processing", "~> 1.2"
gem "mini_magick", "~> 4.12"
gem "view_component"

group :development, :test do
  gem "debug", platforms: %i[mri truffleruby]
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"
  gem "listen"
  gem "rubocop", require: false
  gem "bullet"
end

group :test do
  gem "minitest"
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "shoulda-matchers", "~> 6.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
