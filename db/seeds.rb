# frozen_string_literal: true

Order.destroy_all if defined?(Order) && Order.table_exists?
Product.destroy_all if Product.table_exists?
Category.destroy_all if Category.table_exists?

categories_seed = {
  "Audio" => [
    {
      name: "Aurora Wireless Headphones",
      description: "Premium noise-cancelling headphones with 30-hour battery life and intuitive touch controls.",
      price: 249.99,
      image_url: "https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Pulse Mini Speaker",
      description: "Compact Bluetooth speaker with 360° sound and water-resistant shell for outdoor listening.",
      price: 129.00,
      image_url: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80"
    }
  ],
  "Lighting" => [
    {
      name: "Lumos Smart Lamp",
      description: "Adaptive LED desk lamp with wireless charging pad and customizable color temperatures.",
      price: 129.00,
      image_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Halo Ambient Light",
      description: "Circular wall-mounted light that softly diffuses warm tones for evening relaxation.",
      price: 98.50,
      image_url: "https://images.unsplash.com/photo-1504208434309-cb69f4fe52b0?auto=format&fit=crop&w=800&q=80"
    }
  ],
  "Kitchen" => [
    {
      name: "Cascade Pour-Over Kettle",
      description: "Precision gooseneck kettle with temperature control for craft coffee enthusiasts.",
      price: 89.50,
      image_url: "https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Savor Ceramic Mug Set",
      description: "Set of four hand-fired ceramic mugs with heat-retaining double walls.",
      price: 64.00,
      image_url: "https://images.unsplash.com/photo-1458642849426-cfb724f15ef7?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Harvest Prep Board",
      description: "Acacia wood cutting board with built-in juice groove and magnetic knife rest.",
      price: 72.25,
      image_url: "https://images.unsplash.com/photo-1514996937319-344454492b37?auto=format&fit=crop&w=800&q=80"
    }
  ],
  "Travel" => [
    {
      name: "Horizon Minimal Backpack",
      description: "Water-resistant everyday backpack with dedicated laptop sleeve and modular pockets.",
      price: 159.00,
      image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Voyage Weekender",
      description: "Carry-on friendly duffel crafted from recycled canvas with reinforced leather handles.",
      price: 185.00,
      image_url: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80"
    }
  ],
  "Home Decor" => [
    {
      name: "Nimbus Ceramic Planter",
      description: "Hand-glazed planter with self-watering reservoir to keep your plants thriving.",
      price: 54.75,
      image_url: "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Echo Soft Throw",
      description: "Ultra-soft cotton throw blanket featuring a modern geometric weave.",
      price: 79.95,
      image_url: "https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Arc Deco Mirror",
      description: "Arched wall mirror with brushed brass frame for a minimalist accent.",
      price: 210.00,
      image_url: "https://images.unsplash.com/photo-1523419409543-0c1df022bdd1?auto=format&fit=crop&w=800&q=80"
    }
  ],
  "Wellness" => [
    {
      name: "Serene Aroma Diffuser",
      description: "Ultrasonic diffuser with four timer modes and ambient LED glow.",
      price: 68.00,
      image_url: "https://images.unsplash.com/photo-1556228578-0b5e6fc1356a?auto=format&fit=crop&w=800&q=80"
    },
    {
      name: "Balance Yoga Mat",
      description: "Eco-friendly cork yoga mat with non-slip backing and laser-etched alignment guides.",
      price: 95.00,
      image_url: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80"
    }
  ]
}

categories_seed.each do |category_name, product_list|
  category = Category.create!(name: category_name)
  product_list.each do |attrs|
    Product.create!(attrs.merge(category: category, short_description: attrs[:description]&.truncate(160), stock: rand(10..50)))
  end
end

admin = User.find_or_initialize_by(email: "admin@banhang.test")
admin.update!(
  name: "Store Admin",
  password: "password123",
  role: :admin,
  cart_data: []
)

puts "Seeded #{Category.count} categories and #{Product.count} products. Admin login: admin@banhang.test / password123."
