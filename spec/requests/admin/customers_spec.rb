# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Customers", type: :request do
  let(:admin) { create(:user, :admin, password: "password123") }

  before do
    post session_path, params: { session: { email: admin.email, password: "password123" } }
    follow_redirect!
  end

  describe "GET /admin/customers" do
    it "lists customers" do
      customer = create(:user)

      get admin_customers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(customer.name)
    end
  end

  describe "PATCH /admin/customers/:id/block" do
    it "toggles the blocked status" do
      customer = create(:user)

      patch block_admin_customer_path(customer)
      expect(response).to redirect_to(admin_customers_path)
      expect(customer.reload).to be_blocked

      patch block_admin_customer_path(customer)
      expect(customer.reload).not_to be_blocked
    end
  end
end
