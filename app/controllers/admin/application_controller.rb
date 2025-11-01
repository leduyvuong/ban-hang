# frozen_string_literal: true

module Admin
  class ApplicationController < ::ApplicationController
    include AdminHelper

    layout "admin"
    before_action :require_admin!
    before_action :set_default_meta

    private

    def set_default_meta
      @meta_robots = "noindex,nofollow"
    end

    def set_admin_page(title:, subtitle: nil, actions: nil)
      @admin_page_title = title
      @admin_page_subtitle = subtitle
      @admin_page_actions = actions
      set_page_metadata(title: title)
    end
  end
end
