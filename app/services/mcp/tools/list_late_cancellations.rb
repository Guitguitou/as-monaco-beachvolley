# frozen_string_literal: true

module Mcp
  module Tools
    # Désinscriptions tardives des sessions d'une période (cf. GLOSSARY.md),
    # excusées comprises : qui, quelle session, à quelle heure.
    class ListLateCancellations < Base
      MAX_RESULTS = 300

      tool_name "list_late_cancellations"
      description "Liste les désinscriptions tardives des sessions de la période (date de la session), " \
                  "avec le joueur, la session, l'heure de désinscription et si le Staff l'a excusée. " \
                  "Par défaut : hier et aujourd'hui."
      input_schema(
        properties: {
          from: { type: "string", format: "date", description: "Début inclus (AAAA-MM-JJ). Défaut : hier." },
          to: { type: "string", format: "date", description: "Fin incluse (AAAA-MM-JJ). Défaut : aujourd'hui." }
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, from: nil, to: nil)
          start_on = parse_date(from, Date.current - 1)
          end_on = parse_date(to, Date.current)
          cancellations = LateCancellation.joins(:session)
                                          .where(sessions: { start_at: day_range(start_on, end_on) })
                                          .includes(:user, :session)
                                          .order(:created_at)
                                          .limit(MAX_RESULTS)
                                          .to_a

          {
            from: start_on.iso8601,
            to: end_on.iso8601,
            truncated: cancellations.size == MAX_RESULTS,
            late_cancellations: cancellations.map { |cancellation| serialize(cancellation) }
          }
        end

        private

        def serialize(cancellation)
          {
            id: cancellation.id,
            at: paris_time(cancellation.created_at),
            excused: cancellation.excused,
            player_id: cancellation.user_id,
            player: cancellation.user.full_name,
            session_id: cancellation.session_id,
            session_title: cancellation.session.title,
            session_start_at: paris_time(cancellation.session.start_at)
          }
        end
      end
    end
  end
end
