module RegistrationsHelper
  def registration_open_badge(session_record)
    return unless session_record.entrainement? && session_record.registration_opens_at.present?

    if Time.current < session_record.registration_opens_at
      content_tag(:span, "Pas encore ouvert", class: "ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800")
    elsif Time.current < (session_record.registration_opens_at + Session::PRIORITY_WINDOW_HOURS.hours)
      content_tag(:span, "Priorité compétition (24h)", class: "ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800")
    end
  end
end
