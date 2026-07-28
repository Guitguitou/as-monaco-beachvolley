# frozen_string_literal: true

module Sessions
  # Turns a Session into a downloadable .ics document. This is the only piece that knows
  # about the Session model; the actual iCalendar formatting lives in the reusable
  # Ics::Calendar serializer.
  class IcsExport
    def self.call(session, url: nil)
      new(session, url: url).call
    end

    def initialize(session, url: nil)
      @session = session
      @url = url
    end

    def call
      Ics::Calendar.call(event)
    end

    def filename
      "asmbv-session-#{session.id}.ics"
    end

    private

    attr_reader :session, :url

    def event
      Ics::Event.new(
        uid: "session-#{session.id}@asmbv",
        title: session.title.presence || session.display_name,
        starts_at: session.start_at,
        ends_at: session.end_at,
        description: session.description.presence,
        location: location,
        url: url
      )
    end

    def location
      [ "AS Monaco Beach Volley", session.terrain ].compact.join(" — ")
    end
  end
end
