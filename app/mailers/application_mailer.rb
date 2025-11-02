# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_MAILER_FROM", "no-reply@example.com")
  layout "mailer"
end
