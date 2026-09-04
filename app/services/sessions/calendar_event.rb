# frozen_string_literal: true

module Sessions
  # Builds the Ics::Event describing a Session. Single place that knows how a Session
  # maps to a calendar event, shared by the .ics export and the Google Calendar link.
  class CalendarEvent
    def self.call(session, url: nil)
      new(session, url: url).call
    end

    def initialize(session, url: nil)
      @session = session
      @url = url
    end

    def call
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

    private

    attr_reader :session, :url

    def location
      [ "AS Monaco Beach Volley", session.terrain ].compact.join(" — ")
    end
  end
end
