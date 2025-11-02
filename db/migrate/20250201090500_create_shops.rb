class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :domain
      t.string :time_zone

      t.timestamps
    end

    add_index :shops, :slug, unique: true
  end
end
