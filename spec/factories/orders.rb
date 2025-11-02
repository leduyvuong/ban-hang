# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :user
    total { 0 }
    status { :pending }

    trait :with_items do
      after(:create) do |order|
        product = create(:product)
        create(:order_item, order: order, product: product, quantity: 2, unit_price: product.price, total_price: product.price * 2)
        order.update!(total: order.order_items.sum(:total_price))
      end
    end
  end
end
