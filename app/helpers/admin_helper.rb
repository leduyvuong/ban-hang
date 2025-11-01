# frozen_string_literal: true

module AdminHelper
  def admin_nav_class(path)
    base = "flex items-center gap-2 rounded-xl px-3 py-2 transition"
    current_page?(path) ? "#{base} bg-indigo-50 text-indigo-700 shadow-sm" : "#{base} text-slate-600 hover:bg-slate-100 hover:text-slate-900"
  end
end
