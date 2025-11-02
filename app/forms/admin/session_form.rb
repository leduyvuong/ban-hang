# frozen_string_literal: true

module Admin
  class SessionForm
    include ActiveModel::Model

    attr_accessor :email, :password

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true

    def normalized_email
      email.to_s.strip.downcase
    end
  end
end
