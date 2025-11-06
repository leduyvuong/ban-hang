# frozen_string_literal: true

class Page < ApplicationRecord
  belongs_to :shop

  scope :published, -> { where.not(published_at: nil) }
  scope :published_for_shop, ->(shop) { published.where(shop:).order(published_at: :desc) }

  def components
    layout_config.fetch("components", [])
  end

  def ordered_components
    sort_components(components)
  end

  private

  def sort_components(component_collection)
    Array(component_collection).map do |component|
      normalized = component.deep_dup
      normalized_children = normalized.fetch("children", {})
      normalized["children"] = sort_children(normalized_children)
      normalized
    end.sort_by { |component| component.fetch("order", 0).to_i }
  end

  def sort_children(children_hash)
    return {} unless children_hash.is_a?(Hash)

    children_hash.each_with_object({}) do |(slot, child_components), memo|
      memo[slot] = sort_components(child_components)
    end
  end
end
