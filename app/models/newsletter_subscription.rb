# frozen_string_literal: true

class NewsletterSubscription < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
end
