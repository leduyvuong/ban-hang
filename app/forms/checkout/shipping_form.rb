# frozen_string_literal: true

module Checkout
  class ShippingForm
    include ActiveModel::Model

    ATTRIBUTES = %i[name address city postal_code phone].freeze

    attr_accessor(*ATTRIBUTES)

    validates :name, :address, :city, :postal_code, :phone, presence: true

    def self.from_session(data)
      new(data || {})
    end

    def to_h
      ATTRIBUTES.index_with { |attribute| public_send(attribute).to_s.strip }
    end

    def persisted?
      to_h.values.any?(&:present?)
    end
  end
end
