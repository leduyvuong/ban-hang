# frozen_string_literal: true

module PageLayouts
  class BaseComponent < ViewComponent::Base
    attr_reader :config, :children

    def initialize(config: {}, children: {})
      super()
      @config = config || {}
      @children = children || {}
    end
  end
end
