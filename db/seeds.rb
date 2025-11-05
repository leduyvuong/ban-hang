# frozen_string_literal: true

require "open-uri"
require "faker"

puts "Resetting database..."

AuditLog.delete_all
ShopFeature.delete_all
AdminUser.delete_all
OrderItem.delete_all
Order.delete_all
CurrencyRate.delete_all
ProductDiscount.delete_all
Discount.delete_all
Product.delete_all
Category.delete_all
Feature.delete_all
Shop.destroy_all
User.where.not(email: "admin@banhang.test").delete_all

# --- Categories ---
CATEGORIES = %w[
  Audio
  Lighting
  Kitchen
  Travel
  Home\ Decor
  Wellness
  Tech
  Apparel
  Outdoors
  Beauty
].freeze

categories = CATEGORIES.map { |name| Category.create!(name: name) }

# --- Features ---
FEATURE_SEEDS = [
  { name: "Product Management", slug: "product_management", description: "Manage products and inventory", category: "core" },
  { name: "Order Management", slug: "order_management", description: "Track and fulfill customer orders", category: "core" },
  { name: "Customer Management", slug: "customer_management", description: "Maintain customer profiles and histories", category: "core" },
  { name: "Inventory Tracking", slug: "inventory_tracking", description: "Monitor stock levels across channels", category: "core" },
  { name: "Staff Management", slug: "staff_management", description: "Invite and manage staff accounts", category: "core" },
  { name: "Promotions", slug: "promotions", description: "Create discount codes and campaigns", category: "marketing" },
  { name: "Email Campaigns", slug: "email_campaigns", description: "Send targeted email marketing", category: "marketing" },
  { name: "Newsletter", slug: "newsletter", description: "Collect subscribers and schedule newsletters", category: "marketing" },
  { name: "Loyalty Program", slug: "loyalty_program", description: "Reward customers with loyalty perks", category: "marketing" },
  { name: "Analytics Dashboard", slug: "analytics_dashboard", description: "View performance metrics in real time", category: "analytics" },
  { name: "Custom Reports", slug: "custom_reports", description: "Build tailored analytics reports", category: "analytics" },
  { name: "Customer Segmentation", slug: "customer_segmentation", description: "Segment customers based on behavior", category: "analytics" },
  { name: "POS System", slug: "pos_system", description: "Point of sale for in-store purchases", category: "sales" },
  { name: "Shipping Integration", slug: "shipping_integration", description: "Connect carriers and print shipping labels", category: "sales" },
  { name: "Wholesale Pricing", slug: "wholesale_pricing", description: "Offer tiered pricing for wholesale buyers", category: "sales" },
  { name: "API Access", slug: "api_access", description: "Integrate with the BanHang API", category: "integrations" },
  { name: "Zapier Integration", slug: "zapier_integration", description: "Automate workflows with Zapier", category: "integrations" }
].freeze

puts "Creating features..."

FEATURE_SEEDS.each do |attrs|
  feature = Feature.find_or_initialize_by(slug: attrs[:slug])
  feature.update!(attrs)
end

# --- Shops ---
puts "Creating shops..."

shop_a = Shop.find_or_initialize_by(slug: "shop-a")
shop_a.update!(
  name: "Shop A",
  domain: "shopa.local",
  time_zone: "Asia/Ho_Chi_Minh"
)

shop_b = Shop.find_or_initialize_by(slug: "shop-b")
shop_b.update!(
  name: "Shop B",
  domain: "shopb.local",
  time_zone: "Asia/Ho_Chi_Minh"
)

shops = { shop_a: shop_a, shop_b: shop_b }

# --- Admin Users ---
puts "Creating admin users..."

master_admin = AdminUser.find_or_initialize_by(email: "master@admin.local")
master_admin.update!(
  name: "Master Admin",
  password: "password123",
  role: :master_admin,
  shop: nil
)

owner_shopa = AdminUser.find_or_initialize_by(email: "owner@shopa.local")
owner_shopa.update!(
  name: "Shop A Owner",
  password: "password123",
  role: :shop_owner,
  shop: shop_a
)

owner_shopb = AdminUser.find_or_initialize_by(email: "owner@shopb.local")
owner_shopb.update!(
  name: "Shop B Owner",
  password: "password123",
  role: :shop_owner,
  shop: shop_b
)

# --- Feature Assignments ---
puts "Assigning features to shops..."

basic_feature_slugs = %w[product_management order_management customer_management]
locked_feature_slugs = %w[analytics_dashboard promotions api_access pos_system]

shops.values.each do |shop|
  basic_feature_slugs.each do |slug|
    next if shop.feature_unlocked?(slug)

    shop.unlock_feature!(
      slug,
      unlocked_by: master_admin,
      reason: "Seed: basic feature unlocked"
    )
  end

  locked_feature_slugs.each do |slug|
    feature = Feature.find_by!(slug: slug)
    shop_feature = ShopFeature.find_or_initialize_by(shop: shop, feature: feature)
    next if shop_feature.unlocked?

    shop_feature.status = :locked
    shop_feature.save!
  end
end

# --- Products ---
image_sources = [
  "https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1473951574080-01fe45ec8643?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1532634726-8b9fb99825c7?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1498409785966-ab341407de6e?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=800&q=80"
].freeze

puts "Creating products..."

products = 40.times.map do |index|
  category = categories.sample
  price = Faker::Commerce.price(range: 20.0..350.0).round(2)
  price = 20.0 if price <= 0 # Ensure price is always > 0
  name = "#{Faker::Commerce.product_name} #{index + 1}"
  description = Faker::Lorem.paragraph(sentence_count: 5)
  short_description = Faker::Lorem.sentence(word_count: 14)

  product = Product.create!(
    name: name,
    description: description,
    short_description: short_description,
    price: price,
    price_currency: 'USD',
    price_local_amount: price,
    stock: rand(10..80),
    category: category
  )

  image_url = image_sources[index % image_sources.length]

  begin
    uri = URI.parse(image_url)
    downloaded_image = uri.open
    product.image.attach(
      io: downloaded_image,
      filename: File.basename(uri.path.presence || "product-#{index + 1}.jpg"),
      content_type: downloaded_image.content_type
    )
  rescue StandardError => e
    Rails.logger.warn("Seed image download failed: #{e.message}")
  end

  product
end

puts "Creating discounts..."

spring_sale = Discount.create!(
  name: "Spring Launch Event",
  discount_type: :percentage,
  value: 20,
  start_date: 1.week.ago,
  end_date: 1.month.from_now,
  active: true
)

clearance_boost = Discount.create!(
  name: "Clearance Boost",
  discount_type: :fixed_amount,
  value: 25,
  value_local_amount: 25,
  currency: "USD",
  start_date: 2.days.ago,
  end_date: 2.weeks.from_now,
  active: true
)

summer_preview = Discount.create!(
  name: "Summer Preview",
  discount_type: :percentage,
  value: 15,
  start_date: 1.week.from_now,
  end_date: 2.months.from_now,
  active: true
)

if products.size >= 2
  ProductDiscount.create!(product: products.first, discount: spring_sale)
  ProductDiscount.create!(product: products.second, discount: clearance_boost)
end

# --- Users ---
puts "Creating users..."

customers = 20.times.map do
  name = Faker::Name.unique.name
  User.create!(
    name: name,
    email: Faker::Internet.unique.email(name: name),
    password: "password123",
    phone: Faker::PhoneNumber.phone_number,
    addresses: [
      "#{Faker::Address.street_address}, #{Faker::Address.city}",
      "#{Faker::Address.secondary_address}, #{Faker::Address.city}"
    ]
  )
end

admin = User.find_or_initialize_by(email: "admin@banhang.test")
admin.update!(
  name: "Store Admin",
  password: "password123",
  role: :admin,
  cart_data: [],
  phone: "+84 555 0101",
  addresses: ["123 Admin Lane, District 1, Ho Chi Minh City"]
)

# --- Orders ---
puts "Creating orders..."

statuses = Order.statuses.keys

30.times do
  customer = customers.sample
  order = Order.create!(
    user: customer,
    status: statuses.sample,
    placed_at: rand(1..120).days.ago
  )

  items_count = rand(1..3)
  order_total = 0

  products.sample(items_count).each do |product|
    quantity = rand(1..4)
    line_total = product.price * quantity

    OrderItem.create!(
      order: order,
      product: product,
      quantity: quantity,
      unit_price: product.price,
      total_price: line_total
    )

    order_total += line_total
  end

  order.update!(total: order_total)
end

puts "Seed complete!"
puts "Products: #{Product.count}, Customers: #{User.customers.count}, Orders: #{Order.count}"
puts "Admin login: admin@banhang.test / password123"
puts "Master admin login: master@admin.local / password123"
# --- Currency Rates ---
puts "Configuring currency rates..."
CurrencyRate.upsert_all([
  { currency_code: "EUR", rate_to_base: 1.08, fetched_at: Time.current, source: "Seed" },
  { currency_code: "VND", rate_to_base: 0.00004, fetched_at: Time.current, source: "Seed" }
], unique_by: :currency_code)
