# frozen_string_literal: true

class Shop < ApplicationRecord
  enum homepage_variant: {
    classic: "classic",
    modern: "modern",
    template_3: "template_3"
  }, _suffix: true

  has_many :shop_features, dependent: :destroy
  has_many :features, through: :shop_features
  has_many :audit_logs, dependent: :destroy
  has_many :admin_users
  has_many :users, dependent: :nullify

  validates :name, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 200 }

  before_validation :normalize_slug

  def feature_unlocked?(feature_slug)
    Rails.cache.fetch(feature_cache_key(feature_slug), expires_in: 1.hour) do
      shop_features
        .joins(:feature)
        .where(features: { slug: feature_slug }, status: ShopFeature.statuses[:unlocked])
        .exists?
    end
  end

  def unlocked_features
    shop_features.where(status: :unlocked).includes(:feature).map(&:feature)
  end

  def locked_features
    features.includes(:shop_features) - unlocked_features
  end

  def unlock_feature!(feature_slug, unlocked_by:, reason: nil)
    feature = Feature.find_by!(slug: feature_slug)
    shop_feature = shop_features.find_or_initialize_by(feature: feature)

    shop_feature.update!(
      status: :unlocked,
      unlocked_at: Time.current,
      unlocked_by: unlocked_by,
      notes: reason
    )

    AuditLog.create!(
      admin_user: unlocked_by,
      shop: self,
      feature: feature,
      action: "unlock",
      reason: reason
    )

    invalidate_feature_cache(feature_slug)
    shop_feature
  end

  def lock_feature!(feature_slug, locked_by:, reason: nil)
    feature = Feature.find_by!(slug: feature_slug)
    shop_feature = shop_features.find_by!(feature: feature)

    shop_feature.update!(
      status: :locked,
      notes: reason
    )

    AuditLog.create!(
      admin_user: locked_by,
      shop: self,
      feature: feature,
      action: "lock",
      reason: reason
    )

    invalidate_feature_cache(feature_slug)
    shop_feature
  end

  private

  def feature_cache_key(feature_slug)
    "shop_#{id}_feature_#{feature_slug}"
  end

  def invalidate_feature_cache(feature_slug)
    Rails.cache.delete(feature_cache_key(feature_slug))
    Rails.cache.delete_matched("shop_#{id}_feature_*") if Rails.cache.respond_to?(:delete_matched)
  end

  def normalize_slug
    return if slug.blank?

    self.slug = slug.parameterize
  end
end
