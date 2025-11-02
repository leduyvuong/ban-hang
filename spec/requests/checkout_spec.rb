# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Checkout", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:product) { create(:product, stock: 5, price: 20) }
  let(:shipping_details) do
    {
      name: user.name,
      address: "123 Ruby Way",
      city: "Railsville",
      postal_code: "12345",
      phone: "555-1212"
    }
  end

  before do
    post add_item_cart_path, params: { product_id: product.id, quantity: 2 }
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  it "completes the checkout flow" do
    patch checkout_path, params: { step: "shipping", shipping: shipping_details }
    follow_redirect!

    expect(session[:checkout_shipping]).to be_present

    expect do
      patch checkout_path, params: { step: "payment" }
      follow_redirect!
    end.to change(Order, :count).by(1)
  end
end
