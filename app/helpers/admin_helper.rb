# frozen_string_literal: true

module AdminHelper
  def admin_nav_class(path)
    base = "flex items-center gap-2 rounded-xl px-3 py-2 transition"
    current_page?(path) ? "#{base} bg-indigo-50 text-indigo-700 shadow-sm" : "#{base} text-slate-600 hover:bg-slate-100 hover:text-slate-900"
  end

  # Check if current admin user's shop has access to a feature
  def shop_feature_available?(feature_slug)
    return true if current_admin_user&.master_admin?
    return false unless current_admin_user&.shop

    current_admin_user.shop.feature_unlocked?(feature_slug)
  end

  # Check if feature is locked for current shop
  def shop_feature_locked?(feature_slug)
    !shop_feature_available?(feature_slug)
  end

  # Render content only if feature is available
  def render_if_feature_available(feature_slug, &block)
    return unless shop_feature_available?(feature_slug)

    capture(&block)
  end
end
