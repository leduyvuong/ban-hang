# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cart do
  let(:product) { create(:product, stock: 3) }

  describe "#add_item" do
    it "adds an item within stock" do
      cart = described_class.new
      expect { cart.add_item(product.id, 2) }.to change { cart.items.count }.by(1)
      expect(cart.items.first.quantity).to eq(2)
    end

    it "raises when exceeding stock" do
      cart = described_class.new
      expect { cart.add_item(product.id, 5) }.to raise_error(Cart::OutOfStockError)
    end
  end

  describe "#update_item" do
    it "updates quantity when stock allows" do
      cart = described_class.new
      cart.add_item(product.id, 1)
      cart.update_item(product.id, 2)
      expect(cart.items.first.quantity).to eq(2)
    end
  end
end
