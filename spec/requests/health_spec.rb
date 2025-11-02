# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health endpoint", type: :request do
  it "returns ok" do
    get "/health"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("status" => "ok")
  end
end
