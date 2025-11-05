class AddCurrencyFields < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :price_currency, :string, null: false, default: "USD"
    add_column :products, :price_local_amount, :decimal, precision: 15, scale: 2, null: false, default: 0

    add_column :orders, :currency, :string, null: false, default: "USD"
    add_column :orders, :total_local_amount, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :orders, :exchange_rate, :decimal, precision: 18, scale: 10

    add_column :order_items, :currency, :string, null: false, default: "USD"
    add_column :order_items, :unit_price_local, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :order_items, :total_price_local, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :order_items, :exchange_rate, :decimal, precision: 18, scale: 10

    add_column :discounts, :currency, :string, null: false, default: "USD"
    add_column :discounts, :value_local_amount, :decimal, precision: 15, scale: 2, null: false, default: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE products SET price_local_amount = price, price_currency = 'USD';
          UPDATE orders SET total_local_amount = total, currency = 'USD';
          UPDATE order_items SET unit_price_local = unit_price, total_price_local = total_price, currency = 'USD';
          UPDATE discounts SET value_local_amount = value, currency = 'USD' WHERE discount_type = 1;
        SQL
      end
    end

    add_index :products, :price_currency
    add_index :orders, :currency
    add_index :order_items, :currency
    add_index :discounts, :currency
  end
end
