# frozen_string_literal: true

# Réglages du club modifiables par le Staff (une seule ligne) : lien du
# formulaire d'adhésion et règles du club (prix, fenêtres d'inscription,
# limite de désinscription). `ClubRules.current` est construit à partir d'ici.
class ClubSetting < ApplicationRecord
  SESSION_TYPES = %w[entrainement jeu_libre coaching_prive stage].freeze
  PRICE_ATTRIBUTES = SESSION_TYPES.map { |type| :"#{type}_price_cents" }.freeze
  CANCELLATION_MODES = %w[eve_at_hour hours_before].freeze

  validates :membership_form_url, format: { with: %r{\Ahttps?://\S+\z} }, allow_blank: true
  validates(*PRICE_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
  validates :registration_deadline_hour, :cancellation_deadline_hour,
            numericality: { only_integer: true, in: 0..23 }
  validates :priority_window_hours, :cancellation_hours_before,
            numericality: { only_integer: true, in: 0..72 }
  validates :registration_opening_days, numericality: { only_integer: true, in: 1..30 }
  validates :cancellation_deadline_mode, inclusion: { in: CANCELLATION_MODES }
  validates :season_start_month, numericality: { only_integer: true, in: 1..12 }

  # Les règles mémorisées pour la requête en cours ne sont plus à jour.
  after_commit { CurrentClubRules.reset }

  def self.current
    first_or_create!
  end

  def price_by_type
    SESSION_TYPES.to_h { |type| [ type, public_send(:"#{type}_price_cents") ] }
  end
end
