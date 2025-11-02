class CreateFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :features do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :category, null: false

      t.timestamps
    end

    add_index :features, :slug, unique: true
    add_index :features, :category
  end
end
