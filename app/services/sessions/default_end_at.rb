# frozen_string_literal: true

module Sessions
  # Sans heure de fin saisie, un entraînement, un jeu libre ou un coaching
  # privé dure 90 minutes.
  module DefaultEndAt
    TYPES = %w[entrainement jeu_libre coaching_prive].freeze
    DURATION = 90.minutes

    def self.fill(attributes)
      return attributes if attributes[:end_at].present? || !TYPES.include?(attributes[:session_type])

      start_at = Time.zone.parse(attributes[:start_at].to_s)
      attributes[:end_at] = start_at + DURATION if start_at
      attributes
    rescue ArgumentError
      attributes
    end
  end
end
