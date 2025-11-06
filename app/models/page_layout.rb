# frozen_string_literal: true

class PageLayout < ApplicationRecord
  belongs_to :shop

  DEFAULT_CONFIG = { "components" => [] }.freeze

  before_validation :ensure_layout_config

  validates :layout_config, presence: true

  scope :for_shop, ->(shop) { where(shop:) }

  def components
    layout_config.fetch("components", [])
  end

  def ordered_components
    sort_components(components)
  end

  private

  def ensure_layout_config
    self.layout_config = DEFAULT_CONFIG.deep_dup if layout_config.blank?
  end

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
