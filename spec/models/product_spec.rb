# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    subject { build(:product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:stock).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:category).optional }
  end

  describe ".matching_query" do
    it "returns products matching the name" do
      product = create(:product, name: "Lotus Tea")
      expect(described_class.matching_query("lotus")).to include(product)
    end
  end

  describe ".with_stock_status" do
    it "filters to in-stock products" do
      in_stock = create(:product, stock: 3)
      create(:product, stock: 0)
      expect(described_class.with_stock_status("in_stock")).to contain_exactly(in_stock)
    end
  end

  describe ".ordered_by_param" do
    it "orders by price descending" do
      cheap = create(:product, price: 10)
      pricey = create(:product, price: 100)
      expect(described_class.ordered_by_param("price_high_low").first).to eq(pricey)
    end
  end
end
