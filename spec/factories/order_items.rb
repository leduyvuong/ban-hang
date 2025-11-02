# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    quantity { 1 }
    unit_price { product.price }
    total_price { unit_price * quantity }
  end
end
