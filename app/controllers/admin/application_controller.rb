# frozen_string_literal: true

module Admin
  class ApplicationController < ::ApplicationController
    include AdminHelper

    layout "admin"
    before_action :authenticate_admin_user!
    before_action :set_default_meta

    helper_method :current_admin_user, :admin_user_signed_in?

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

    def current_admin_user
      return @current_admin_user if defined?(@current_admin_user)

      admin_user_id = session[:admin_user_id]
      @current_admin_user = AdminUser.find_by(id: admin_user_id) if admin_user_id
    end

    def admin_user_signed_in?
      current_admin_user.present? || admin?
    end

    def authenticate_admin_user!
      return if current_admin_user.present? || admin?

      flash[:alert] = "Please log in as an admin."
      redirect_to admin_login_path
    end

    def ensure_master_admin!
      return if current_admin_user&.is_master_admin? || current_user&.admin?

      flash[:alert] = "Unauthorized"
      redirect_to admin_root_path
    end
  end
end
