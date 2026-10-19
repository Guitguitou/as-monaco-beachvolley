# frozen_string_literal: true

module Sessions
  # Événements FullCalendar du calendrier des sessions, vus par un joueur.
  #
  # La couleur d'un événement porte le statut du joueur (inscrit, en attente,
  # ouvert, indisponible) plutôt que le terrain : c'est ce qui décide d'un clic.
  # Le terrain devient un libellé court, et le remplissage est affiché sur
  # l'événement lui-même. Toutes les données sont chargées en trois requêtes,
  # quel que soit le nombre de sessions.
  class CalendarEvents
    CLOSURES_LOOKBACK = 3.months

    def initialize(user:, sessions:, url_for:)
      @user = user
      @sessions = sessions.to_a
      @url_for = url_for
    end

    def sessions
      @sessions.map { |session| session_event(session) }
    end

    # Fermetures de terrain, en événements d'arrière-plan sur les jours concernés.
    # Toutes les fermetures récentes sont envoyées : le calendrier change de
    # semaine côté client, sans recharger la page.
    def closures
      TerrainClosure.where(ends_on: (Time.zone.today - CLOSURES_LOOKBACK)..).order(:starts_on).map do |closure|
        {
          start: closure.starts_on.iso8601,
          end: (closure.ends_on + 1.day).iso8601,
          display: "background",
          classNames: [ "terrain-closure" ],
          title: [ "#{closure.terrain} fermé", closure.reason.presence ].compact.join(" · "),
          terrain: closure.terrain
        }
      end
    end

    private

    def session_event(session)
      count = confirmed_counts[session.id].to_i
      for_me = level_allowed?(session)
      status = status_for(session, count, for_me)
      label = status_label(status, count, session.max_players)

      {
        id: session.id,
        title: session.title,
        shortTitle: short_title(session.title),
        start: session.start_at.iso8601,
        end: session.end_at.iso8601,
        url: @url_for.call(session),
        classNames: [ "status-#{status}", "terrain-#{session.terrain.to_s.delete_prefix("Terrain ")}" ],
        status: status,
        terrain: session.terrain,
        terrainShort: session.terrain.to_s.delete_prefix("Terrain ").then { |n| n.present? ? "T#{n}" : "" },
        forMe: for_me,
        coachName: session.user&.full_name,
        confirmedCount: count,
        maxPlayers: session.max_players,
        statusText: label.first,
        statusTone: label.last
      }
    end

    def status_for(session, count, for_me)
      registration = registrations[session.id]
      return "registered" if registration&.confirmed?
      return "waitlisted" if registration&.waitlisted?
      return "unavailable" unless for_me
      return "unavailable" if session.end_at < Time.current
      return "unavailable" if session.max_players.present? && count >= session.max_players

      "open"
    end

    # Ce que le joueur doit savoir avant de cliquer : son statut, sinon les
    # places restantes. Le ton règle la pastille et la jauge.
    def status_label(status, count, max)
      return [ "✓ Inscrit", "registered" ] if status == "registered"
      return [ "Liste d'attente", "waitlisted" ] if status == "waitlisted"
      return [ "#{count} inscrits", status == "open" ? "ok" : "full" ] if max.blank?

      left = max - count
      return [ "Complet", "full" ] if left <= 0
      return [ "#{count}/#{max}", "full" ] unless status == "open"
      return [ left == 1 ? "Plus qu’1 place" : "Plus que #{left} places", "hot" ] if left <= 2

      [ "#{count}/#{max} · #{left} places", "ok" ]
    end

    def level_allowed?(session)
      !session.entrainement? || session.levels.empty? || (session.level_ids & user_level_ids).any?
    end

    def short_title(title)
      title.to_s
        .gsub(/Entra[iî]nement/i, "Entr.")
        .gsub(/\s*–\s*/, " ")
        .gsub(/\s+Mixte/i, " Mx")
    end

    def registrations
      @registrations ||= @user.registrations.where(session_id: session_ids).index_by(&:session_id)
    end

    def confirmed_counts
      @confirmed_counts ||= Registration.confirmed.where(session_id: session_ids).group(:session_id).count
    end

    def user_level_ids
      @user_level_ids ||= @user.levels.pluck(:id)
    end

    def session_ids
      @session_ids ||= @sessions.map(&:id)
    end
  end
end
