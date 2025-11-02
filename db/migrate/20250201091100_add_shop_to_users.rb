class AddShopToUsers < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :shop_id)
      add_reference :users, :shop, foreign_key: true
    end
  end
end
