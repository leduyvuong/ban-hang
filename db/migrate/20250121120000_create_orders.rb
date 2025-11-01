class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :order_number, null: false
      t.decimal :total, precision: 10, scale: 2, default: "0.0", null: false
      t.string :status, null: false, default: "pending"
      t.datetime :placed_at

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
  end
end
