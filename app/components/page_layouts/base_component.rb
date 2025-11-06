# frozen_string_literal: true

module PageLayouts
  class BaseComponent < ViewComponent::Base
    attr_reader :config

    def initialize(config: {})
      super()
      @config = config || {}
    end
  end
end
