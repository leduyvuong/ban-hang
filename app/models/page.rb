# frozen_string_literal: true

class Page < ApplicationRecord
  belongs_to :shop

  scope :published, -> { where.not(published_at: nil) }
  scope :published_for_shop, ->(shop) { published.where(shop:).order(published_at: :desc) }

  def components
    layout_config.fetch("components", [])
  end

  def ordered_components
    components.sort_by { |component| component.fetch("order", 0).to_i }
  end
end
