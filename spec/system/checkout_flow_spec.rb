# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CheckoutFlow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "lets a customer complete a checkout" do
    product = create(:product, name: "Ceramic Bowl", price: 25, stock: 10)
    user = create(:user, password: "password123")

    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    page.driver.post add_item_cart_path, params: { product_id: product.id, quantity: 1 }
    visit checkout_path

    fill_in "Full name", with: "Jane Customer"
    fill_in "Street address", with: "42 Ruby Road"
    fill_in "City", with: "Rails City"
    fill_in "Postal code", with: "54321"
    fill_in "Phone number", with: "5551212"
    click_button "Continue to review"

    click_button "Continue to payment"
    click_button "Place order"

    expect(page).to have_content("Order placed")
  end
end
