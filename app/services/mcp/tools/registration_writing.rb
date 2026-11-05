# frozen_string_literal: true

module Mcp
  module Tools
    # Ce que partagent les tools qui inscrivent ou désinscrivent un joueur :
    # la permission, le schéma commun et la session renvoyée avec ses effectifs.
    class RegistrationWriting
      PERMISSION = SessionWriting::PERMISSION
      PROPERTIES = {
        session_id: { type: "integer" },
        player_id: { type: "integer", description: "Joueur (cf. list_players)." }
      }.freeze

      def self.serialize(session)
        counts = session.registrations.group(:status).count
        SessionWriting.serialize(session).merge(
          confirmed_count: counts.fetch("confirmed", 0), waitlisted_count: counts.fetch("waitlisted", 0)
        )
      end
    end
  end
end
