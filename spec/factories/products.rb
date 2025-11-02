# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    association :category
    name { Faker::Commerce.unique.product_name }
    description { Faker::Lorem.paragraph }
    short_description { Faker::Lorem.sentence }
    price { Faker::Commerce.price(range: 10.0..200.0) }
    stock { rand(5..25) }
  end
end
