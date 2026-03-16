# frozen_string_literal: true

class IcalService
  def initialize(session)
    @session = session
  end

  def to_ics
    [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//AS Monaco Beach Volley//Sessions//FR",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      format_vevent,
      "END:VCALENDAR"
    ].join("\r\n")
  end

  private

  def format_vevent
    title = @session.title.presence || @session.session_type.humanize
    desc = [@session.description, "Terrain: #{@session.terrain}"].compact.join("\n")
    url = build_session_url

    [
      "BEGIN:VEVENT",
      "UID:session-#{@session.id}@#{ical_host}",
      "DTSTAMP:#{format_ical_time(Time.current)}",
      "DTSTART:#{format_ical_time(@session.start_at)}",
      "DTEND:#{format_ical_time(@session.end_at)}",
      "SUMMARY:#{escape_ical(title)}",
      "DESCRIPTION:#{escape_ical(desc)}",
      "URL:#{url}",
      "END:VEVENT"
    ].join("\r\n")
  end

  def format_ical_time(time)
    return "" if time.blank?
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def escape_ical(str)
    return "" if str.blank?
    str.to_s.gsub("\\", "\\\\").gsub(",", "\\,").gsub(";", "\\;").tr("\n", " ")
  end

  def ical_host
    opts = Rails.application.config.action_mailer.default_url_options || {}
    opts[:host].presence || "localhost"
  end

  def build_session_url
    host = ical_host
    opts = Rails.application.config.action_mailer.default_url_options || {}
    port = opts[:port]
    scheme = opts[:protocol] || opts[:scheme] || "http"
    base = "#{scheme}://#{host}"
    base += ":#{port}" if port.present? && !([80, 443].include?(port.to_i))
    "#{base}/sessions/#{@session.id}"
  end
end
