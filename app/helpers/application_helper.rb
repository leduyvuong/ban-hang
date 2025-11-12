# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  include CurrencyHelper
  DEFAULT_META_TITLE = "BanHang"
  DEFAULT_META_DESCRIPTION = "Shop curated Vietnamese products delivered fast with BanHang."

  def page_title
    [@page_title, DEFAULT_META_TITLE].compact.join(" | ")
  end

  def page_description
    @page_description.presence || DEFAULT_META_DESCRIPTION
  end

  def canonical_url
    @canonical_url.presence || request.original_url
  end

  def meta_robots
    @meta_robots.presence
  end

  def open_graph_tags
    defaults = {
      title: page_title,
      description: page_description,
      image: nil,
      url: canonical_url,
      type: "website"
    }

    defaults.merge(@open_graph || {})
  end

  def error_class(object, attribute, classes = "border-rose-300 focus:border-rose-500 focus:ring-rose-100")
    return "" unless object&.respond_to?(:errors)
    object.errors.include?(attribute) ? classes : ""
  end

  def field_error(object, attribute)
    return unless object&.errors&.include?(attribute)

    content_tag(:p, object.errors.full_messages_for(attribute).first, class: "mt-1 text-xs text-rose-600")
  end

  # Feature availability check
  # For multi-tenant apps, this checks if the current shop has the feature unlocked
  def feature_available?(feature_slug, shop = nil)
    # If no shop context, assume feature is available (for single-tenant or testing)
    return true if shop.nil?
    
    shop.feature_unlocked?(feature_slug)
  end

  # Check if feature is locked
  def feature_locked?(feature_slug, shop = nil)
    !feature_available?(feature_slug, shop)
  end

  def user_initials(user)
    name = user.name.to_s.strip
    initials = name.split.map { |part| part.first }.join.upcase
    initials = initials.first(2) if initials.length > 2
    return initials if initials.present?

    user.email.to_s.first(2).upcase
  end

  def set_page_metadata(title: nil, description: nil, canonical: nil, robots: nil)
    @page_title = title if title.present?
    @page_description = description if description.present?
    @canonical_url = canonical if canonical.present?
    @meta_robots = robots if robots.present?
  end

  def homepage_section_href(section, fallback: nil)
    if modern_homepage_enabled?
      current_page?(root_path) ? "##{section}" : root_path(anchor: section)
    else
      fallback_value(fallback) || root_path
    end
  end

  def route_defined?(helper_name)
    respond_to?(helper_name, true)
  end

  def user_avatar_tag(user, size: :md, class_name: "")
    size_classes = {
      sm: "h-9 w-9 text-xs",
      md: "h-10 w-10 text-sm",
      lg: "h-12 w-12 text-base"
    }

    classes = [
      "flex items-center justify-center rounded-full bg-teal-500/10 font-semibold text-teal-600",
      size_classes.fetch(size, size_classes[:md]),
      class_name
    ].reject(&:blank?).join(" ")

    content_tag(:div, user_initials(user), class: classes)
  end

  def render_rating_stars(rating, max: 5)
    filled = [[rating.to_f.round, 0].max, max].min
    empty = max - filled

    stars = []
    stars << content_tag(:span, "★" * filled, class: "text-amber-500") if filled.positive?
    stars << content_tag(:span, "☆" * empty, class: "text-gray-300") if empty.positive?
    safe_join(stars)
  end

  private

  def fallback_value(value)
    case value
    when Proc
      value.call
    else
      value
    end
  end
end
