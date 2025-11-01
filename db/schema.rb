# frozen_string_literal: true

ActiveRecord::Schema[7.1].define(version: 2025_01_01_120000) do
  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
