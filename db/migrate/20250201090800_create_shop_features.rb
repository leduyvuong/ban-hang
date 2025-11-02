class CreateShopFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_features do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :unlocked_at
      t.references :unlocked_by, foreign_key: { to_table: :admin_users }
      t.text :notes

      t.timestamps
    end

    add_index :shop_features, [:shop_id, :feature_id], unique: true
  end
end
