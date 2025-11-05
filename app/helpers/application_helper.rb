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
end
