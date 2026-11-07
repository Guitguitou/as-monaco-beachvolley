# frozen_string_literal: true

module Mcp
  module Tools
    # Désinscrit un joueur comme un admin dans l'app : remboursé dans les
    # délais, désinscription tardive tracée sinon, sauf si elle est excusée
    # (cf. GLOSSARY.md). La place libérée revient à la liste d'attente.
    class UnregisterPlayer < Base
      tool_name "unregister_player"
      description "Désinscrit un joueur d'une session (admins uniquement). Après la date limite d'annulation, " \
                  "le joueur n'est pas remboursé, sauf désinscription excusée."
      input_schema(
        properties: {
          **RegistrationWriting::PROPERTIES,
          excused: { type: "boolean", description: "Excuser une désinscription tardive : le joueur est remboursé. Défaut : false." }
        },
        required: %w[session_id player_id]
      )
      annotations(**WRITE, destructive_hint: true)

      class << self
        def permission = RegistrationWriting::PERMISSION

        def execute(_context, session_id:, player_id:, excused: false)
          session = Session.find(session_id)
          registration = session.registrations.find_by(user_id: player_id)
          raise ArgumentError, "Ce joueur n'est pas inscrit à cette session." unless registration

          cancellation = Registrations::Cancellation.new(registration, excused:)
          message = cancellation.call
          { message:, refunded: cancellation.refundable?, session: RegistrationWriting.serialize(session.reload) }
        end
      end
    end
  end
end
