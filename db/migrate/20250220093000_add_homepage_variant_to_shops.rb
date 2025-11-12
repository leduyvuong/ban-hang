# frozen_string_literal: true

class AddHomepageVariantToShops < ActiveRecord::Migration[7.1]
  def change
    add_column :shops, :homepage_variant, :string, null: false, default: "classic"
    add_index :shops, :homepage_variant
  end
end
