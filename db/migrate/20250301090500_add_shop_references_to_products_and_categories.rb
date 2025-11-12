class AddShopReferencesToProductsAndCategories < ActiveRecord::Migration[7.1]
  def change
    add_reference :products, :shop, foreign_key: true
    add_reference :categories, :shop, foreign_key: true
  end
end
