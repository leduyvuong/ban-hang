class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true

    change_table :products do |t|
      t.references :category, foreign_key: true
    end
  end
end
