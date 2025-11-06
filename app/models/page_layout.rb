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
    components.sort_by { |component| component.fetch("order", 0).to_i }
  end

  private

  def ensure_layout_config
    self.layout_config = DEFAULT_CONFIG.deep_dup if layout_config.blank?
  end
end
