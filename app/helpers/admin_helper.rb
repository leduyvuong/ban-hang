# frozen_string_literal: true

module AdminHelper
  def admin_nav_class(path)
    base = "flex items-center gap-2 rounded-xl px-3 py-2 transition"
    current_page?(path) ? "#{base} bg-indigo-50 text-indigo-700 shadow-sm" : "#{base} text-slate-600 hover:bg-slate-100 hover:text-slate-900"
  end

  # Check if current admin user's shop has access to a feature
  def shop_feature_available?(feature_slug)
    return true if current_admin_user&.master_admin? || current_user&.admin?
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

  def discount_status_badge(discount)
    now = Time.current
    label, style =
      if !discount.active?
        ["Inactive", "bg-slate-100 text-slate-600"]
      elsif discount.end_date.present? && discount.end_date < now
        ["Expired", "bg-rose-100 text-rose-700"]
      elsif discount.start_date.present? && discount.start_date > now
        ["Scheduled", "bg-amber-100 text-amber-700"]
      else
        ["Active", "bg-emerald-100 text-emerald-700"]
      end

    content_tag(:span, label, class: "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide #{style}")
  end
end
