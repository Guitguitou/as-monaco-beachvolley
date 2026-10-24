# frozen_string_literal: true

module Sessions
  # Valeurs qu'une session tient de son type : le prix, et pour un
  # entraînement, l'ouverture des inscriptions et la limite de désinscription
  # remboursée (règles du club), sauf si elles ont été saisies.
  module TypeDefaults
    def self.apply(session, rules: ClubRules.current)
      session.price = rules.price_for(session.session_type)
      session.entrainement? ? training_dates(session, rules) : (session.registration_opens_at = nil)
      session
    end

    def self.training_dates(session, rules)
      return if session.start_at.blank?

      session.registration_opens_at ||= rules.registration_opens_at_for(session.start_at)
      session.cancellation_deadline_at ||= rules.cancellation_deadline_for(session.start_at)
    end
    private_class_method :training_dates
  end
end
