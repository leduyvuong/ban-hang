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

    def primary_button_text
      config.fetch("primary_button_text", "Khám phá ngay")
    end

    def primary_button_url
      config.fetch("primary_button_url", "#products")
    end

    def secondary_button_text
      config.fetch("secondary_button_text", "Bộ sưu tập")
    end

    def secondary_button_url
      config.fetch("secondary_button_url", "#collections")
    end
  end
end
