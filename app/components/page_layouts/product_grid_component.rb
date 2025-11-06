# frozen_string_literal: true

module PageLayouts
  class ProductGridComponent < BaseComponent
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

    def product_ids
      Array(config["product_ids"]).map(&:to_i)
    end

    def products
      @products ||= begin
        scope = Product.includes(image_attachment: :blob)
        if product_ids.present?
          records = scope.where(id: product_ids).index_by(&:id)
          product_ids.filter_map { |id| records[id] }
        else
          scope.limit(6)
        end
      end
    end
  end
end
