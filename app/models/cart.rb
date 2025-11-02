# frozen_string_literal: true

require "active_model"
require "active_support/core_ext/string/inflections"

class Cart
  class OutOfStockError < StandardError; end

  class Item
    include ActiveModel::Validations

    attr_reader :product_id, :product
    attr_accessor :quantity

    validates :product_id, numericality: { only_integer: true, greater_than: 0 }
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }
    validate :product_available

    def initialize(product_id:, quantity: 1)
      @product_id = product_id.to_i
      self.quantity = quantity
      @product = nil
    end

    def quantity=(value)
      @quantity = value.to_i
    end

    def product=(value)
      @product = value
      @product_id = value.id if value
    end

    def subtotal
      return 0 unless product

      product.price * quantity
    end

    private

    def product_available
      return unless product

      available = product.stock.to_i
      if available.zero?
        errors.add(:base, "#{product.name} is currently out of stock.")
      elsif quantity > available
        errors.add(:base, "Only #{available} #{'unit'.pluralize(available)} of #{product.name} available.")
      end
    end
  end

  attr_reader :items

  def initialize(items: [])
    @items = items
  end

  def self.from_session(serialized)
    return new if serialized.blank?

    items = Array(serialized).filter_map do |entry|
      product_id = entry.with_indifferent_access[:product_id].to_i
      quantity = entry.with_indifferent_access[:quantity].to_i
      next if product_id.zero? || quantity <= 0

      Item.new(product_id: product_id, quantity: quantity)
    end

    new(items: items)
  end

  def self.from_user(user)
    return new if user.blank?

    from_session(user.cart_items)
  end

  def add_item(product_id, quantity = 1)
    quantity = sanitize_quantity(quantity)
    return if quantity <= 0

    product = find_product!(product_id)
    item = find_item(product.id)
    desired_quantity = quantity
    desired_quantity += item.quantity if item

    ensure_stock!(product, desired_quantity)

    if item
      item.product ||= product
      item.quantity = desired_quantity
      validate_item!(item)
    else
      new_item = Item.new(product_id: product.id, quantity: quantity)
      new_item.product = product
      validate_item!(new_item)
      @items << new_item
    end
  end

  def merge!(other_cart)
    return self if other_cart.nil?

    other_cart.items.each do |item|
      add_item(item.product_id, item.quantity)
    end

    self
  end

  def update_item(product_id, quantity)
    item = find_item(product_id)
    return unless item

    quantity = sanitize_quantity(quantity, allow_zero: true)
    return @items.delete(item) if quantity <= 0

    product = find_product!(product_id)
    ensure_stock!(product, quantity)
    item.product ||= product
    item.quantity = quantity
    validate_item!(item)
  end

  def remove_item(product_id)
    item = find_item(product_id)
    @items.delete(item) if item
  end

  def clear
    @items.clear
  end

  def empty?
    @items.empty?
  end

  def total_items
    items.sum(&:quantity)
  end

  def subtotal
    items_with_products.sum(&:subtotal)
  end

  def items_with_products
    preload_products
    items
  end

  def serialize
    items.map do |item|
      {
        "product_id" => item.product_id,
        "quantity" => item.quantity
      }
    end
  end

  def preload_products
    ids = items.map(&:product_id).uniq
    return if ids.empty?

    products = Product.includes(image_attachment: { blob: :variant_records }).where(id: ids).index_by(&:id)

    items.select! do |item|
      product = products[item.product_id]
      item.product = product
      product.present?
    end
  end

  private

  def find_item(product_id)
    pid = normalize_id(product_id)
    items.find { |item| item.product_id == pid }
  end

  def find_product!(product_id)
    Product.find(normalize_id(product_id))
  end

  def sanitize_quantity(value, allow_zero: false)
    quantity = value.to_i
    return quantity if allow_zero && quantity.zero?

    [quantity, 1].max
  end

  def normalize_id(value)
    value.to_i
  end

  def ensure_stock!(product, requested_quantity)
    candidate = Item.new(product_id: product.id, quantity: requested_quantity)
    candidate.product = product
    validate_item!(candidate)
  end

  def validate_item!(item)
    return if item.valid?

    message = item.errors.full_messages.first || "Unable to update cart item."
    raise OutOfStockError, message
  end
end
