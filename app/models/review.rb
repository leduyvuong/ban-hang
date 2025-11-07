# frozen_string_literal: true

class Review < ApplicationRecord
  LINK_REGEX = %r{https?://|www\.}i
  HTML_TAG_REGEX = %r{</?([a-z][a-z0-9]*)\b[^>]*>}i
  PROFANITY_WORDS = %w[
    shit fuck asshole bastard bitch damn cunt dick pussy slut whore motherfucker
    địt lồn cặc đụ buồi
  ].freeze
  PROFANITY_REGEX = Regexp.union(
    PROFANITY_WORDS.map { |word| /(?<!\p{Alnum})#{Regexp.escape(word)}(?!\p{Alnum})/i }
  )

  belongs_to :user
  belongs_to :product

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, length: { maximum: 2000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :product_id, message: "has already reviewed this product" }
  validate :comment_must_be_clean

  scope :recent_first, -> { order(created_at: :desc) }
  scope :visible, -> { where(hidden_at: nil) }
  scope :hidden, -> { where.not(hidden_at: nil) }

  def hide!
    update!(hidden_at: Time.current)
  end

  def show!
    update!(hidden_at: nil)
  end

  def hidden?
    hidden_at.present?
  end

  private

  def comment_must_be_clean
    return if comment.blank?

    if comment.match?(LINK_REGEX)
      errors.add(:comment, "cannot include links")
    end

    if comment.match?(HTML_TAG_REGEX)
      errors.add(:comment, "cannot include HTML")
    end

    if PROFANITY_REGEX.match?(comment)
      errors.add(:comment, "contains inappropriate language")
    end
  end
end
