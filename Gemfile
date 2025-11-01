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

group :development, :test do
  gem "debug", platforms: %i[mri truffleruby]
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"
  gem "listen"
  gem "rubocop", require: false
end

group :test do
  gem "minitest"
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
