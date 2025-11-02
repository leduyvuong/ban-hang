class AddShopToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:admin_users, :shop_id)
      add_reference :admin_users, :shop, foreign_key: true, index: true
    end

    unless column_exists?(:admin_users, :role)
      add_column :admin_users, :role, :integer, null: false, default: 0
    end
  end
end
