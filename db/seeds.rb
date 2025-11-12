# frozen_string_literal: true

require "open-uri"
require "faker"

puts "Resetting database..."

AuditLog.delete_all
ShopFeature.delete_all
AdminUser.delete_all
Review.delete_all
WishlistItem.delete_all
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

# --- Features ---
puts "Creating features..."

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

FEATURE_SEEDS.each do |attrs|
  feature = Feature.find_or_initialize_by(slug: attrs[:slug])
  feature.update!(attrs)
end

# --- Users (create owners first, before shops) ---
puts "Creating shop owner users..."

owner_a = User.find_or_initialize_by(email: "owner-a@banhang.test")
owner_a.update!(
  name: "Alice Nguyen",
  password: "password123",
  role: :shop_owner,
  phone: "+84 555 0100",
  addresses: ["100 Owner Street, District 1, Ho Chi Minh City"]
)

owner_b = User.find_or_initialize_by(email: "owner-b@banhang.test")
owner_b.update!(
  name: "Bob Tran",
  password: "password123",
  role: :shop_owner,
  phone: "+84 555 0200",
  addresses: ["200 Business Avenue, District 3, Ho Chi Minh City"]
)

# --- Shops ---
puts "Creating shops..."

shop_a = Shop.find_or_initialize_by(slug: "shop-a")
shop_a.update!(
  name: "Shop A",
  domain: "shop-a.local",
  time_zone: "Asia/Ho_Chi_Minh",
  homepage_variant: :modern,
  status: :active,
  owner: owner_a
)

shop_b = Shop.find_or_initialize_by(slug: "shop-b")
shop_b.update!(
  name: "Shop B",
  domain: "shop-b.local",
  time_zone: "Asia/Ho_Chi_Minh",
  homepage_variant: :classic,
  status: :active,
  owner: owner_b
)

# --- Admin Users ---
puts "Creating admin users..."

master_admin = AdminUser.find_or_initialize_by(email: "master@admin.local")
master_admin.update!(
  name: "Master Admin",
  password: "password123",
  role: :master_admin,
  shop: nil
)

admin_a = AdminUser.find_or_initialize_by(email: "admin-a@shop-a.test")
admin_a.update!(
  name: "Admin Shop A",
  password: "password123",
  role: :shop_owner,
  shop: shop_a
)

admin_b = AdminUser.find_or_initialize_by(email: "admin-b@shop-b.test")
admin_b.update!(
  name: "Admin Shop B",
  password: "password123",
  role: :shop_owner,
  shop: shop_b
)

# --- Feature Assignments ---
puts "Assigning features to shops..."

basic_feature_slugs = %w[product_management order_management customer_management inventory_tracking staff_management]
premium_feature_slugs = %w[analytics_dashboard promotions email_campaigns newsletter]
locked_feature_slugs = %w[api_access pos_system wholesale_pricing loyalty_program]

# Unlock features for Shop A (basic + premium)
basic_feature_slugs.each do |slug|
  next if shop_a.feature_unlocked?(slug)

  shop_a.unlock_feature!(
    slug,
    unlocked_by: master_admin,
    reason: "Seed: basic feature unlocked"
  )
end

premium_feature_slugs.each do |slug|
  next if shop_a.feature_unlocked?(slug)

  shop_a.unlock_feature!(
    slug,
    unlocked_by: master_admin,
    reason: "Seed: premium feature unlocked"
  )
end

# Unlock only basic features for Shop B
basic_feature_slugs.each do |slug|
  next if shop_b.feature_unlocked?(slug)

  shop_b.unlock_feature!(
    slug,
    unlocked_by: master_admin,
    reason: "Seed: basic feature unlocked"
  )
end

# Lock premium features for both shops
locked_feature_slugs.each do |slug|
  feature = Feature.find_by!(slug: slug)
  
  [shop_a, shop_b].each do |shop|
    shop_feature = ShopFeature.find_or_initialize_by(shop: shop, feature: feature)
    next if shop_feature.unlocked?

    shop_feature.status = :locked
    shop_feature.save!
  end
end

# --- Categories ---
puts "Creating categories..."

CATEGORIES_A = %w[
  Audio
  Lighting
  Kitchen
  Travel
  Home\ Decor
].freeze

CATEGORIES_B = %w[
  Wellness
  Tech
  Apparel
  Outdoors
  Beauty
].freeze

categories_a = CATEGORIES_A.map { |name| Category.create!(name: name, shop: shop_a) }
categories_b = CATEGORIES_B.map { |name| Category.create!(name: name, shop: shop_b) }

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

# Create 20 products for Shop A and 20 for Shop B
products = []

40.times do |index|
  # Alternate between shops
  current_shop = index < 20 ? shop_a : shop_b
  shop_categories = index < 20 ? categories_a : categories_b
  category = shop_categories.sample
  
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
    category: category,
    shop: current_shop
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

  products << product
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

if products.size >= 2
  ProductDiscount.create!(product: products.first, discount: spring_sale)
  ProductDiscount.create!(product: products.second, discount: clearance_boost)
end

# --- Users ---
puts "Creating users..."

# Create 10 customers for Shop A and 10 for Shop B
customers = []

10.times do
  name = Faker::Name.unique.name
  customers << User.create!(
    name: name,
    email: Faker::Internet.unique.email(name: name),
    password: "password123",
    phone: Faker::PhoneNumber.phone_number,
    shop: shop_a,
    addresses: [
      "#{Faker::Address.street_address}, #{Faker::Address.city}",
      "#{Faker::Address.secondary_address}, #{Faker::Address.city}"
    ]
  )
end

10.times do
  name = Faker::Name.unique.name
  customers << User.create!(
    name: name,
    email: Faker::Internet.unique.email(name: name),
    password: "password123",
    phone: Faker::PhoneNumber.phone_number,
    shop: shop_b,
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
  shop: shop_a,
  addresses: ["123 Admin Lane, District 1, Ho Chi Minh City"]
)

# --- Reviews ---
puts "Creating reviews..."

review_comments = [
  "Great build quality and fast shipping.",
  "Exactly what I needed, works perfectly.",
  "Solid value for the price and easy to set up.",
  "The design is beautiful and the materials feel premium.",
  "Customer support was helpful and the item works as described.",
  "Reliable performance with no issues so far.",
  "Packaging was excellent and the product exceeded expectations.",
  "Good quality overall, would purchase again.",
  "Setup was straightforward and the manual was clear.",
  "Feels sturdy and looks great in my home."
]

customers.each do |customer|
  sample_size = rand(3..5)
  # Only review products from the same shop
  shop_products = products.select { |p| p.shop_id == customer.shop_id }
  shop_products.sample(sample_size).each do |product|
    comment = review_comments.sample
    comment = nil if rand < 0.2

    review = Review.create!(
      user: customer,
      product: product,
      rating: rand(3..5),
      comment: comment
    )

    review.hide! if rand < 0.15
  end
end

# --- Wishlists ---
puts "Creating wishlist items..."

customers.each do |customer|
  # Only wishlist products from the same shop
  shop_products = products.select { |p| p.shop_id == customer.shop_id }
  shop_products.sample(rand(4..7)).each do |product|
    WishlistItem.create!(user: customer, product: product)
  end
end

# --- Orders ---
puts "Creating orders..."

statuses = Order.statuses.keys

30.times do
  customer = customers.sample
  customer_shop = customer.shop
  
  order = Order.create!(
    user: customer,
    shop: customer_shop,
    status: statuses.sample,
    placed_at: rand(1..120).days.ago
  )

  items_count = rand(1..3)
  order_total = 0

  # Only order products from the same shop
  shop_products = products.select { |p| p.shop_id == customer_shop.id }
  shop_products.sample(items_count).each do |product|
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
puts "Shops: #{Shop.count}"
puts "  - Shop A (modern template): #{Product.joins(:category).where(categories: { shop: shop_a }).count} products"
puts "  - Shop B (classic template): #{Product.joins(:category).where(categories: { shop: shop_b }).count} products"
puts "Products: #{Product.count}, Customers: #{User.customers.count}, Orders: #{Order.count}"
puts "Reviews: #{Review.count} (visible: #{Review.visible.count}, hidden: #{Review.hidden.count})"
puts "Wishlist items: #{WishlistItem.count}"
puts ""
puts "Login credentials:"
puts "  Master admin: master@admin.local / password123"
puts "  Shop A admin: admin-a@shop-a.test / password123"
puts "  Shop B admin: admin-b@shop-b.test / password123"
puts "  Customer: admin@banhang.test / password123"
# --- Currency Rates ---
puts "Configuring currency rates..."
CurrencyRate.upsert_all([
  { currency_code: "EUR", rate_to_base: 1.08, fetched_at: Time.current, source: "Seed" },
  { currency_code: "VND", rate_to_base: 0.00004, fetched_at: Time.current, source: "Seed" }
], unique_by: :currency_code)
