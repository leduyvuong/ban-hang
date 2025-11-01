# frozen_string_literal: true

Product.destroy_all if Product.table_exists?

products = [
  {
    name: "Aurora Wireless Headphones",
    description: "Premium noise-cancelling headphones with 30-hour battery life and intuitive touch controls.",
    price: 249.99,
    image_url: "https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=crop&w=800&q=80"
  },
  {
    name: "Lumos Smart Lamp",
    description: "Adaptive LED desk lamp with wireless charging pad and customizable color temperatures.",
    price: 129.00,
    image_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80"
  },
  {
    name: "Cascade Pour-Over Kettle",
    description: "Precision gooseneck kettle with temperature control for craft coffee enthusiasts.",
    price: 89.50,
    image_url: "https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=800&q=80"
  },
  {
    name: "Horizon Minimal Backpack",
    description: "Water-resistant everyday backpack with dedicated laptop sleeve and modular pockets.",
    price: 159.00,
    image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80"
  },
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
  }
]

products.each do |attrs|
  Product.create!(attrs)
end

puts "Seeded #{Product.count} products."
