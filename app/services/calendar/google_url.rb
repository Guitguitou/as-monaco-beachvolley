# frozen_string_literal: true

module Calendar
  # Builds a Google Calendar "add event" URL from an Ics::Event.
  #
  # Sur Android, ce lien ouvre directement l'app Google Agenda sur l'écran de création
  # d'événement pré-rempli — pas de fichier .ics à télécharger puis à ouvrir.
  class GoogleUrl
    BASE = "https://calendar.google.com/calendar/render"

    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      "#{BASE}?#{params.to_query}"
    end

    private

    attr_reader :event

    def params
      {
        action: "TEMPLATE",
        text: event.title,
        dates: "#{format_time(event.starts_at)}/#{format_time(event.ends_at)}",
        details: details,
        location: event.location
      }.compact_blank
    end

    def details
      [ event.description, event.url ].compact_blank.join("\n\n")
    end

    def format_time(time)
      time.utc.strftime("%Y%m%dT%H%M%SZ")
    end
  end
end
