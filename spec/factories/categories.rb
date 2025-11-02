# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    name { Faker::Commerce.unique.department(max: 1, fixed_amount: true) }
  end
end
