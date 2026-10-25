# frozen_string_literal: true

# Page publique qui affiche une web app Google Apps Script dans une iframe,
# servie à la racine du site : https://as-monaco-beachvolley.com/{slug}.
class PublicPage < ApplicationRecord
  SCRIPT_URL_FORMAT = %r{\Ahttps://script\.google\.com/macros/s/[\w-]+/exec\z}
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  before_validation :normalize_slug

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :script_url, presence: true, format: { with: SCRIPT_URL_FORMAT, message: "doit être une URL https://script.google.com/macros/s/…/exec" }
  validate :slug_not_reserved

  scope :ordered, -> { order(:title) }

  # Premiers segments déjà pris par les routes de l'app (« admin », « sessions »…).
  def self.reserved_slugs
    @reserved_slugs ||= Rails.application.routes.routes
      .map { |route| route.path.spec.to_s.split("/")[1].to_s.sub(/\(.*\z/, "") }
      .reject { |segment| segment.empty? || segment.start_with?(":", "*") }
      .to_set
  end

  def to_param
    slug_was.presence || slug
  end

  private

  def normalize_slug
    source = slug.presence || title
    self.slug = source.to_s.parameterize if source.present?
  end

  def slug_not_reserved
    errors.add(:slug, "est déjà utilisé par une page de l'application") if self.class.reserved_slugs.include?(slug)
  end
end
