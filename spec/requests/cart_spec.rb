# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cart", type: :request do
  let(:product) { create(:product, stock: 5) }

  describe "POST /cart/add_item" do
    it "adds an item to the cart" do
      post add_item_cart_path, params: { product_id: product.id, quantity: 2 }

      follow_redirect!
      get cart_path
      expect(response.body).to include(product.name)
      expect(response.body).to include('value="2"')
    end
  end

  describe "PATCH /cart/update_item" do
    it "updates quantity" do
      post add_item_cart_path, params: { product_id: product.id, quantity: 1 }
      patch update_item_cart_path, params: { product_id: product.id, quantity: 3 }

      get cart_path
      expect(response.body).to include('value="3"')
    end
  end
end
