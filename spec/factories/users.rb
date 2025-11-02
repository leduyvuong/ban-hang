# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email(domain: "banhang.test") }
    password { "password123" }
    role { :customer }

    trait :admin do
      role { :admin }
    end
  end
end
