# frozen_string_literal: true

module PageLayouts
  class FeatureSectionComponent < BaseComponent
    def title
      config.fetch("title", "")
    end

    def subtitle
      config.fetch("subtitle", "")
    end

    def background_color
      config.fetch("background_color", "#ffffff")
    end

    def text_color
      config.fetch("text_color", "#0f172a")
    end

    def features
      Array(config["features"]).map do |feature|
        feature.with_indifferent_access
      end
    end
  end
end
