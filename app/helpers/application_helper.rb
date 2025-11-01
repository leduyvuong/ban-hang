# frozen_string_literal: true

module ApplicationHelper
  DEFAULT_META_TITLE = "BanHang".freeze
  DEFAULT_META_DESCRIPTION = "Shop curated Vietnamese products delivered fast with BanHang.".freeze

  def set_page_metadata(title: nil, description: nil, canonical: nil)
    @page_title = title if title.present?
    @page_description = description if description.present?
    @canonical_url = canonical if canonical.present?
  end

  def page_title
    [@page_title, DEFAULT_META_TITLE].compact.join(" | ")
  end

  def page_description
    @page_description.presence || DEFAULT_META_DESCRIPTION
  end

  def canonical_url
    @canonical_url.presence || request.original_url
  end
end
