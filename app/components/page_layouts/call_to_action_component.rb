# frozen_string_literal: true

module PageLayouts
  class CallToActionComponent < BaseComponent
    def title
      config.fetch("title", "")
    end

    def subtitle
      config.fetch("subtitle", "")
    end

    def background_color
      config.fetch("background_color", "#1d4ed8")
    end

    def text_color
      config.fetch("text_color", "#f8fafc")
    end

    def button_text
      config.fetch("button_text", "Bắt đầu ngay")
    end

    def button_url
      config.fetch("button_url", "#")
    end
  end
end
