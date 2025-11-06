# frozen_string_literal: true

module PageLayouts
  class HeroBannerComponent < BaseComponent
    def title
      config.fetch("title", "")
    end

    def subtitle
      config.fetch("subtitle", "")
    end

    def background_color
      config.fetch("background_color", "#0f172a")
    end

    def text_color
      config.fetch("text_color", "#f8fafc")
    end

    def image_url
      config.fetch("image_url", nil)
    end
  end
end
