# frozen_string_literal: true

require "securerandom"

class AddSlugAndShortDescriptionToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :slug, :string
    add_column :products, :short_description, :string, limit: 180

    add_index :products, :slug, unique: true

    reversible do |dir|
      dir.up do
        say_with_time "Backfilling product slugs and short descriptions" do
          backfill_product_slugs!
        end
      end
    end
  end

  private

  def backfill_product_slugs!
    product_class = Class.new(ApplicationRecord) do
      self.table_name = "products"
    end

    product_class.reset_column_information

    product_class.find_each do |product|
      product.update_columns(
        slug: generate_unique_slug(product_class, product),
        short_description: derive_short_description(product)
      )
    end
  end

  def generate_unique_slug(scope, product)
    base_slug = product.name.to_s.parameterize
    base_slug = "#{base_slug}-#{SecureRandom.hex(2)}" if base_slug.blank?
    candidate = base_slug
    counter = 2

    while scope.where.not(id: product.id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate
  end

  def derive_short_description(product)
    source = product.short_description.presence || product.description.to_s
    source.truncate(180)
  end
end
