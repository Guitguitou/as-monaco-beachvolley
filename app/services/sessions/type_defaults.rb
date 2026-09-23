# frozen_string_literal: true

module Sessions
  # Valeurs qu'une session tient de son type : le prix, et pour un
  # entraînement, l'ouverture des inscriptions (7 jours avant) et la limite de
  # désinscription remboursée (22h la veille), sauf si elles ont été saisies.
  module TypeDefaults
    def self.apply(session)
      session.price = Session::PRICE_BY_TYPE[session.session_type] || 0
      session.entrainement? ? training_dates(session) : (session.registration_opens_at = nil)
      session
    end

    def self.training_dates(session)
      return if session.start_at.blank?

      session.registration_opens_at ||= session.start_at - 7.days
      session.cancellation_deadline_at ||= (session.start_at - 1.day).change(hour: 22, min: 0)
    end
    private_class_method :training_dates
  end
end
