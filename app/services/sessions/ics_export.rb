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
      CalendarEvent.call(session, url: url)
    end
  end
end
