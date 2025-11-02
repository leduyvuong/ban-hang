# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkout::OrderProcessor do
  let(:user) { create(:user) }
  let(:shipping_params) do
    {
      "name" => user.name,
      "address" => "123 Ruby Way",
      "city" => "Railsville",
      "postal_code" => "12345",
      "phone" => "555-1212"
    }
  end

  let(:product) { create(:product, price: 25.0, stock: 10) }
  let(:cart) do
    Cart.new(items: [Cart::Item.new(product_id: product.id, quantity: 2)]).tap do |cart|
      cart.preload_products
    end
  end

  subject(:service) { described_class.new(user: user, cart: cart, shipping: shipping_params) }

  describe "#call" do
    it "creates an order and enqueues confirmation" do
      expect { service.call }.to have_enqueued_job(OrderConfirmationJob)
      expect(Order.count).to eq(1)
      expect(Order.last.order_items.first.quantity).to eq(2)
    end

    it "reduces stock and enqueues low stock alerts when below threshold" do
      product.update!(stock: 4)
      expect { service.call }.to have_enqueued_job(LowStockAlertJob).with(product.id)
      expect(product.reload.stock).to eq(2)
    end

    it "raises when stock unavailable" do
      product.update!(stock: 1)
      expect { service.call }.to raise_error(Checkout::OrderProcessor::StockError)
    end
  end
end
