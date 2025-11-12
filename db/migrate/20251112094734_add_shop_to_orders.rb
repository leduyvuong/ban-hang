class AddShopToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :shop, null: true, foreign_key: true
    
    # Backfill existing orders with shop from first product's category
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE orders
          SET shop_id = (
            SELECT products.shop_id
            FROM order_items
            INNER JOIN products ON products.id = order_items.product_id
            WHERE order_items.order_id = orders.id
            LIMIT 1
          )
          WHERE shop_id IS NULL
        SQL
        
        change_column_null :orders, :shop_id, false
      end
    end
  end
end
