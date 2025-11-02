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
5. Copy `.env.example` to `.env` (or configure environment variables another way) and populate values for local SMTP/Redis if needed.
6. Start the development services:
   ```sh
   bin/dev      # Rails + Tailwind
   bundle exec sidekiq -C config/sidekiq.yml
   ```
   This runs both the Rails server and Tailwind watcher (via Foreman).

## Testing

RSpec is configured alongside the existing Minitest suite.

```sh
bundle exec rspec
```

To run the legacy Minitest suite:

```sh
bundle exec rails test
```

## Deployment Checklist

- Provision PostgreSQL and Redis; expose connection strings via `DATABASE_URL` and `REDIS_URL`.
- Configure `DEFAULT_MAILER_FROM`, `DEFAULT_ADMIN_EMAIL`, and SMTP credentials for Action Mailer.
- Precompile assets: `bundle exec rails assets:precompile`.
- Run migrations (including Active Storage and index optimisations).
- Ensure Sidekiq is running (`bundle exec sidekiq -C config/sidekiq.yml`).
- Set `SENTRY_DSN` (or equivalent) for error monitoring.
- Verify `/health` endpoint is reachable by the load balancer.
- Enable `RAILS_SERVE_STATIC_FILES` if using the built-in file server.
- Update CDN/static caches after deploy to honor long-lived cache headers.

## Seeds

The seed file (`db/seeds.rb`) loads six showcase products complete with descriptions, pricing and imagery.
