class CreateDiscounts < ActiveRecord::Migration[7.1]
  def change
    create_table :discounts do |t|
      t.string :name, null: false
      t.integer :discount_type, null: false, default: 0
      t.decimal :value, precision: 8, scale: 2, null: false
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :discounts, :active
    add_index :discounts, :start_date
    add_index :discounts, :end_date
  end
end
