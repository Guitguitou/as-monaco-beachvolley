# frozen_string_literal: true

# Compétition homologuée organisée par le club. L'inscription se fait sur BVS ;
# l'app la met en avant, encaisse les frais via son Pack tournoi et occupe les
# terrains dans l'agenda (Sessions de type tournoi, dérivées du tournoi).
# Navigation unidirectionnelle : Pack et Session portent tournament_id.
class Tournament < ApplicationRecord
  LEVELS = %w[S3 S2 S1 Elite].freeze

  has_many_attached :images

  validates :title, :starts_on, :ends_on, :start_time, :end_time, presence: true
  validates :level, inclusion: { in: LEVELS }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :points, :teams_count, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :registration_link, format: { with: %r{\Ahttps?://}i, message: "doit commencer par http(s)://" }, allow_blank: true
  validate :ends_on_after_starts_on
  validate :end_time_after_start_time
  validate :terrains_allowed

  scope :upcoming, -> { where("ends_on >= ?", Date.current).order(:starts_on) }
  scope :past, -> { where("ends_on < ?", Date.current).order(starts_on: :desc) }

  def self.featured
    upcoming.first
  end

  def upcoming?
    ends_on >= Date.current
  end

  def price
    price_cents.to_i / 100.0
  end

  def price=(euros)
    self.price_cents = euros.blank? ? nil : (euros.to_f * 100).round
  end

  def level_label
    [ level, points ].compact.join(" · ")
  end

  def days
    (starts_on..ends_on).to_a
  end

  # Noms des terrains occupés, tels que Session les connaît ("Terrain 1"…).
  def terrain_names
    Session.terrains.invert.values_at(*terrains).compact
  end

  def terrain_names=(names)
    self.terrains = Array(names).compact_blank.map { |name| Session.terrains.fetch(name) }
  end

  def pack
    Pack.find_by(tournament_id: id)
  end

  def sessions
    Session.where(tournament_id: id)
  end

  def payment_open?
    pack&.active? || false
  end

  def paid_by?(user)
    return false if user.nil? || pack.nil?

    CreditPurchase.paid_status.exists?(user_id: user.id, pack_id: pack.id)
  end

  # Images dans l'ordre choisi par l'admin ; la première est la couverture.
  def ordered_images
    images.attachments.sort_by { |attachment| image_order.index(attachment.id) || Float::INFINITY }
  end

  def cover_image
    ordered_images.first
  end

  # Ordre choisi par l'admin (glisser-déposer) ; les ids inconnus sont ignorés.
  def reorder_images(attachment_ids)
    known = images.attachments.map(&:id)
    update!(image_order: attachment_ids.map(&:to_i) & known)
  end

  private

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?
    errors.add(:ends_on, "doit être après la date de début") if ends_on < starts_on
  end

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end

  def terrains_allowed
    errors.add(:terrains, "contient un terrain inconnu") unless (terrains - Session.terrains.values).empty?
  end
end
