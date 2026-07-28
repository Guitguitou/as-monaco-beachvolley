# frozen_string_literal: true

module Ics
  # Serializes one or more Ics::Event objects into a valid iCalendar (RFC 5545) document.
  # Framework-agnostic: give it events, get back a .ics string that Apple Calendar,
  # Google Calendar and Outlook can all import.
  class Calendar
    PRODID = "-//AS Monaco Beach Volley//Sessions//FR"
    MAX_OCTETS = 75

    def self.call(events)
      new(events).to_ics
    end

    def initialize(events)
      @events = Array(events)
    end

    def to_ics
      lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:#{PRODID}",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH"
      ]
      @events.each { |event| lines.concat(event_lines(event)) }
      lines << "END:VCALENDAR"
      lines.map { |line| fold(line) }.join("\r\n") + "\r\n"
    end

    private

    def event_lines(event)
      [
        "BEGIN:VEVENT",
        "UID:#{event.uid}",
        "DTSTAMP:#{format_time(Time.now)}",
        "DTSTART:#{format_time(event.starts_at)}",
        "DTEND:#{format_time(event.ends_at)}",
        "SUMMARY:#{escape(event.title)}",
        *optional_line("DESCRIPTION", event.description),
        *optional_line("LOCATION", event.location),
        *optional_line("URL", event.url),
        "END:VEVENT"
      ]
    end

    def optional_line(name, value)
      value.present? ? [ "#{name}:#{escape(value)}" ] : []
    end

    def format_time(time)
      time.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    # RFC 5545 TEXT escaping.
    def escape(text)
      text.to_s
          .gsub(/\r\n?/, "\n")
          .gsub(/[\\;,\n]/) do |char|
            case char
            when "\\" then "\\\\"
            when ";" then "\\;"
            when "," then "\\,"
            when "\n" then "\\n"
            end
          end
    end

    # RFC 5545 line folding: content lines longer than 75 octets are split, with each
    # continuation line prefixed by a single space. Splits on character boundaries so
    # multibyte UTF-8 is never cut in half.
    def fold(line)
      return line if line.bytesize <= MAX_OCTETS

      folded = +""
      current = +""
      limit = MAX_OCTETS
      line.each_char do |char|
        if current.bytesize + char.bytesize > limit
          folded << current << "\r\n "
          current = +"#{char}"
          limit = MAX_OCTETS - 1 # continuation lines reserve one octet for the leading space
        else
          current << char
        end
      end
      folded << current
    end
  end
end
