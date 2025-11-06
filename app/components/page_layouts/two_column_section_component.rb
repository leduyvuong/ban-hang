# frozen_string_literal: true

module PageLayouts
  class TwoColumnSectionComponent < BaseComponent
    GAP_CLASSES = {
      "sm" => "gap-6",
      "md" => "gap-8",
      "lg" => "gap-12"
    }.freeze

    def background_color
      config.fetch("background_color", "#ffffff")
    end

    def gap_class
      GAP_CLASSES.fetch(config.fetch("gap", "lg"), GAP_CLASSES["lg"])
    end

    def left_components
      ordered_children("left")
    end

    def right_components
      ordered_children("right")
    end

    def render_child(component_config)
      component = ComponentRegistry.find(component_config["type"])
      return unless component

      component.component_class.new(
        config: component_config["config"] || component.default_config.deep_dup,
        children: component_config["children"] || {}
      )
    end

    private

    def ordered_children(slot)
      Array(children.fetch(slot, [])).sort_by { |child| child.fetch("order", 0).to_i }
    end
  end
end
