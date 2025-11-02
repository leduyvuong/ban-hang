# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
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
end
