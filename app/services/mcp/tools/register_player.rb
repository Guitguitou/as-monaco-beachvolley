# frozen_string_literal: true

module Mcp
  module Tools
    # Inscrit un joueur à une session comme un admin dans l'app : crédits
    # débités, priorité appliquée, date limite de 17h ignorée. Refuse un joueur
    # qui ne « Peut pas réserver » (cf. GLOSSARY.md, ADR 0004).
    class RegisterPlayer < Base
      tool_name "register_player"
      description "Inscrit un joueur à une session (admins uniquement), en liste principale (débitée) ou en liste d'attente."
      input_schema(
        properties: {
          **RegistrationWriting::PROPERTIES,
          waitlist: { type: "boolean", description: "Inscrire en liste d'attente (session pleine) ; promu aussitôt s'il reste une place. Défaut : false." }
        },
        required: %w[session_id player_id]
      )
      annotations(**WRITE)

      class << self
        def permission = RegistrationWriting::PERMISSION

        def execute(_context, session_id:, player_id:, waitlist: false)
          session = Session.find(session_id)
          player = User.find(player_id)
          raise ArgumentError, "#{player.full_name} ne peut pas réserver (licence ou dossier incomplet)." unless player.peut_reserver?

          result = Registrations::Enrollment.new(user: player, session:, waitlist:, privileged: true).call
          raise ArgumentError, result.message unless result.success?

          status = session.registrations.find_by!(user: player).status
          { status:, message: result.message, session: RegistrationWriting.serialize(session.reload) }
        end
      end
    end
  end
end
