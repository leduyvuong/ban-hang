# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_06_063826) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "analyzed_at"
    t.datetime "identified_at"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "shop_id"
    t.integer "role", default: 0, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["shop_id"], name: "index_admin_users_on_shop_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "shop_id", null: false
    t.bigint "feature_id", null: false
    t.string "action", null: false
    t.text "reason"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["admin_user_id"], name: "index_audit_logs_on_admin_user_id"
    t.index ["feature_id"], name: "index_audit_logs_on_feature_id"
    t.index ["shop_id", "feature_id", "created_at"], name: "index_audit_logs_on_shop_feature_and_timestamp"
    t.index ["shop_id"], name: "index_audit_logs_on_shop_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "currency_rates", force: :cascade do |t|
    t.string "currency_code", null: false
    t.string "base_currency", default: "USD", null: false
    t.decimal "rate_to_base", precision: 18, scale: 10, null: false
    t.datetime "fetched_at"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_code"], name: "index_currency_rates_on_currency_code", unique: true
  end

  create_table "discounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "discount_type", default: 0, null: false
    t.decimal "value", precision: 8, scale: 2, null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "USD", null: false
    t.decimal "value_local_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.index ["active"], name: "index_discounts_on_active"
    t.index ["currency"], name: "index_discounts_on_currency"
    t.index ["end_date"], name: "index_discounts_on_end_date"
    t.index ["start_date"], name: "index_discounts_on_start_date"
  end

  create_table "features", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_features_on_category"
    t.index ["slug"], name: "index_features_on_slug", unique: true
  end

  create_table "newsletter_subscriptions", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscriptions_on_email", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "USD", null: false
    t.decimal "unit_price_local", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "total_price_local", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "exchange_rate", precision: 18, scale: 10
    t.index ["currency"], name: "index_order_items_on_currency"
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "pending", null: false
    t.datetime "placed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "currency", default: "USD", null: false
    t.decimal "total_local_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "exchange_rate", precision: 18, scale: 10
    t.index ["currency"], name: "index_orders_on_currency"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id", "status"], name: "index_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_discounts", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "discount_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_id"], name: "index_product_discounts_on_discount_id"
    t.index ["product_id"], name: "index_product_discounts_on_product_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "short_description", limit: 180
    t.bigint "category_id"
    t.integer "stock", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.decimal "price_local_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["price_currency"], name: "index_products_on_price_currency"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "page_layouts", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.jsonb "layout_config", default: {"components"=>[]}, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_page_layouts_on_published_at"
    t.index ["shop_id"], name: "index_page_layouts_on_shop_id"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.jsonb "layout_config", default: {"components"=>[]}, null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_pages_on_published_at"
    t.index ["shop_id"], name: "index_pages_on_shop_id"
  end

  create_table "shop_features", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "feature_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "unlocked_at"
    t.bigint "unlocked_by_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id"], name: "index_shop_features_on_feature_id"
    t.index ["shop_id", "feature_id"], name: "index_shop_features_on_shop_id_and_feature_id", unique: true
    t.index ["shop_id"], name: "index_shop_features_on_shop_id"
    t.index ["unlocked_by_id"], name: "index_shop_features_on_unlocked_by_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "domain"
    t.string "time_zone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_shops_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.jsonb "cart_data", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.jsonb "addresses", default: [], null: false
    t.datetime "blocked_at"
    t.bigint "shop_id"
    t.index ["blocked_at"], name: "index_users_on_blocked_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_users", "shops"
  add_foreign_key "audit_logs", "admin_users"
  add_foreign_key "audit_logs", "features"
  add_foreign_key "audit_logs", "shops"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "page_layouts", "shops"
  add_foreign_key "pages", "shops"
  add_foreign_key "product_discounts", "discounts"
  add_foreign_key "product_discounts", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "shop_features", "admin_users", column: "unlocked_by_id"
  add_foreign_key "shop_features", "features"
  add_foreign_key "shop_features", "shops"
  add_foreign_key "users", "shops"
end
