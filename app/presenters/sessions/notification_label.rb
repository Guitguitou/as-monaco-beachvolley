# frozen_string_literal: true

module Sessions
  # Nom, date et heure d'une session tels que les disent les notifications et
  # les e-mails : « Entraînement G1 du 14/03/2030 à 19h30 ».
  class NotificationLabel
    def initialize(session)
      @session = session
    end

    def name
      @session.title || @session.session_type.humanize
    end

    def date
      @session.start_at.strftime("%d/%m/%Y")
    end

    def time
      @session.start_at.strftime("%Hh%M")
    end

    def to_s
      "#{name} du #{date} à #{time}"
    end
  end
end
