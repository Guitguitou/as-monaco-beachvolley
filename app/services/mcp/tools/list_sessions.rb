# frozen_string_literal: true

module Mcp
  module Tools
    # Sessions sur une période, avec leur remplissage.
    class ListSessions < Base
      MAX_RESULTS = 200

      tool_name "list_sessions"
      description "Liste les sessions (entraînements, jeu libre, coachings privés, stages, tournois) " \
                  "sur une période, avec inscrits confirmés, liste d'attente et places restantes. " \
                  "Par défaut : les 7 prochains jours."
      input_schema(
        properties: {
          from: { type: "string", format: "date", description: "Début inclus (AAAA-MM-JJ). Défaut : aujourd'hui." },
          to: { type: "string", format: "date", description: "Fin incluse (AAAA-MM-JJ). Défaut : début + 7 jours." },
          session_type: { type: "string", enum: Session.session_types.keys },
          level_id: { type: "integer", description: "Ne garder que les sessions ouvertes à ce niveau (cf. list_level_groups)." }
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, Session ]

        def execute(_context, from: nil, to: nil, session_type: nil, level_id: nil)
          start_on = parse_date(from, Date.current)
          end_on = parse_date(to, start_on + 7.days)
          sessions = scope(start_on, end_on, session_type, level_id).to_a
          counts = Registration.where(session_id: sessions.map(&:id)).group(:session_id, :status).count

          {
            from: start_on.iso8601,
            to: end_on.iso8601,
            truncated: sessions.size == MAX_RESULTS,
            sessions: sessions.map { |session| serialize(session, counts) }
          }
        end

        private

        def scope(start_on, end_on, session_type, level_id)
          sessions = Session.where(start_at: start_on.beginning_of_day..end_on.end_of_day)
                            .includes(:user, :levels)
                            .ordered_by_start
                            .limit(MAX_RESULTS)
          sessions = sessions.where(session_type: session_type) if session_type.present?
          sessions = sessions.where(id: SessionLevel.where(level_id: level_id).select(:session_id)) if level_id.present?
          sessions
        end

        def serialize(session, counts)
          confirmed = counts.fetch([ session.id, "confirmed" ], 0)
          {
            id: session.id,
            title: session.title,
            session_type: session.session_type,
            start_at: paris_time(session.start_at),
            end_at: paris_time(session.end_at),
            terrain: session.terrain,
            coach: session.user&.full_name,
            levels: session.levels.map(&:display_name),
            price_credits: session.price,
            max_players: session.max_players,
            confirmed_count: confirmed,
            waitlisted_count: counts.fetch([ session.id, "waitlisted" ], 0),
            places_left: session.max_players && [ session.max_players - confirmed, 0 ].max
          }
        end
      end
    end
  end
end
