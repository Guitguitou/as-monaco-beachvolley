# frozen_string_literal: true

module Mcp
  module Tools
    # Tournois organisés par le club.
    class ListTournaments < Base
      tool_name "list_tournaments"
      description "Liste les tournois du club : dates, niveau, lieu, prix, nombre d'équipes. " \
                  "Par défaut seuls les tournois à venir ou en cours."
      input_schema(
        properties: { include_past: { type: "boolean", description: "Inclure les tournois passés." } }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, Tournament ]

        def execute(_context, include_past: false)
          tournaments = Tournament.order(:starts_on)
          tournaments = tournaments.where(ends_on: Date.current..) unless include_past

          {
            tournaments: tournaments.map do |tournament|
              {
                id: tournament.id,
                title: tournament.title,
                starts_on: tournament.starts_on.iso8601,
                ends_on: tournament.ends_on.iso8601,
                level: tournament.level,
                location: tournament.location,
                price_eur: tournament.price_cents / 100.0,
                teams_count: tournament.teams_count,
                points: tournament.points
              }
            end
          }
        end
      end
    end
  end
end
