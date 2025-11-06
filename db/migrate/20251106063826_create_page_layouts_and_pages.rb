# frozen_string_literal: true

class CreatePageLayoutsAndPages < ActiveRecord::Migration[7.1]
  def change
    create_table :page_layouts do |t|
      t.references :shop, null: false, foreign_key: true
      t.jsonb :layout_config, null: false, default: { components: [] }
      t.datetime :published_at

      t.timestamps
    end

    create_table :pages do |t|
      t.references :shop, null: false, foreign_key: true
      t.jsonb :layout_config, null: false, default: { components: [] }
      t.datetime :published_at, null: false

      t.timestamps
    end

    add_index :page_layouts, :published_at
    add_index :pages, :published_at
  end
end
