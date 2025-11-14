class CreateShopUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_users do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "staff"
      t.timestamps
    end

    add_index :shop_users, [:shop_id, :user_id], unique: true
  end
end
