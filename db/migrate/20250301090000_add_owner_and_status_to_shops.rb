class AddOwnerAndStatusToShops < ActiveRecord::Migration[7.1]
  def change
    add_reference :shops, :owner, foreign_key: { to_table: :users }
    add_column :shops, :status, :string, null: false, default: "draft"
    add_index :shops, :status

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE shops
          SET owner_id = source.owner_id
          FROM (
            SELECT DISTINCT ON (shop_id) shop_id, id AS owner_id
            FROM users
            WHERE shop_id IS NOT NULL
            ORDER BY shop_id, role DESC, id
          ) AS source
          WHERE shops.id = source.shop_id AND shops.owner_id IS NULL;
        SQL
      end
    end
  end
end
