# frozen_string_literal: true

module PageLayouts
  class NewsletterSignupComponent < BaseComponent
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

    def button_text
      config.fetch("button_text", "Đăng ký")
    end
  end
end
