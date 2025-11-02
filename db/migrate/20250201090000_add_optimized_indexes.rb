# frozen_string_literal: true

class AddOptimizedIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :products, :category_id unless index_exists?(:products, :category_id)
    add_index :order_items, [:order_id, :product_id], name: "index_order_items_on_order_id_and_product_id" unless index_exists?(:order_items, [:order_id, :product_id])
    add_index :orders, [:user_id, :status], name: "index_orders_on_user_id_and_status" unless index_exists?(:orders, [:user_id, :status])
  end
end
