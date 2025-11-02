# frozen_string_literal: true

class SessionForm
  include ActiveModel::Model

  attr_accessor :email, :password, :remember_me

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true

  def remember_me=(value)
    @remember_me = ActiveModel::Type::Boolean.new.cast(value)
  end

  def remember_me
    ActiveModel::Type::Boolean.new.cast(@remember_me)
  end
end
