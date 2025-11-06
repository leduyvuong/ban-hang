# frozen_string_literal: true

module PageLayouts
  class TestimonialsComponent < BaseComponent
    def title
      config.fetch("title", "")
    end

    def subtitle
      config.fetch("subtitle", "")
    end

    def background_color
      config.fetch("background_color", "#f8fafc")
    end

    def text_color
      config.fetch("text_color", "#0f172a")
    end

    def testimonials
      Array(config["testimonials"]).map do |testimonial|
        testimonial.with_indifferent_access
      end
    end
  end
end
