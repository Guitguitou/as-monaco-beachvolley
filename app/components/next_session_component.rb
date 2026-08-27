# frozen_string_literal: true

# La prochaine session du joueur, en grand, en tête de « Mon terrain ».
#
# C'est la réponse à la seule question qu'il se pose en ouvrant l'app.
class NextSessionComponent < ApplicationComponent
  MAX_AVATARS = 6

  def initialize(registration:)
    @registration = registration
  end

  private

  attr_reader :registration

  def session
    registration.session
  end

  def waitlisted?
    registration.waitlisted?
  end

  def title
    session.title.presence || session.display_name
  end

  def day_label
    l(session.start_at.to_date, format: :day_and_month)
  end

  def time_range
    "#{l(session.start_at, format: :time)} – #{l(session.end_at, format: :time)}"
  end

  def terrain_label
    session.terrain.to_s.split("_").last
  end

  # Compte à rebours en clair : « aujourd'hui », « demain », « dans 3 jours ».
  def countdown
    days = (session.start_at.to_date - Date.current).to_i

    case days
    when ..-1 then "en cours"
    when 0 then "aujourd'hui"
    when 1 then "demain"
    when 2..6 then "dans #{days} jours"
    else "dans #{days / 7} semaine#{'s' if days / 7 > 1}"
    end
  end

  def teammates
    @teammates ||= session.registrations
      .select { |r| r.confirmed? && r.user_id != registration.user_id }
      .sort_by { |r| r.created_at || Time.current }
      .map(&:user)
      .compact
  end

  def extra_teammates
    [ teammates.size - MAX_AVATARS, 0 ].max
  end

  def teammates_sentence
    return "Personne d'autre pour l'instant" if teammates.empty?

    names = teammates.first(2).map { |u| u.first_name.presence || u.full_name }
    others = teammates.size - names.size

    return "Avec #{names.to_sentence(two_words_connector: ' et ', last_word_connector: ' et ')}" if others.zero?

    "Avec #{names.join(', ')} et #{others} autre#{'s' if others > 1}"
  end
end
