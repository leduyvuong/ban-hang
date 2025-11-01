# BanHang

A Rails 7 storefront starter configured with PostgreSQL, Hotwire (Turbo + Stimulus) and Tailwind CSS.

## Rails new command

```sh
rails new . -d postgresql --css tailwind
```

## Getting started

1. Install Ruby 3.4.4 and bundler.
2. Run `bundle install` to install dependencies.
3. Configure PostgreSQL credentials in `config/database.yml` or set the environment variables referenced in that file.
4. Prepare the database:
   ```sh
   bin/rails db:prepare
   bin/rails db:seed
   ```
5. Start the development servers:
   ```sh
   bin/dev
   ```
   This runs both the Rails server and Tailwind watcher (via Foreman).

## Seeds

The seed file (`db/seeds.rb`) loads six showcase products complete with descriptions, pricing and imagery.
