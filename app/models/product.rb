# frozen_string_literal: true

class Product < ApplicationRecord
  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
