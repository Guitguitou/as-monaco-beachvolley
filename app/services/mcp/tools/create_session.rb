# frozen_string_literal: true

module Mcp
  module Tools
    # Crée une session, comme le formulaire de l'admin (sans inscrits).
    class CreateSession < Base
      tool_name "create_session"
      description "Crée une session (admins uniquement). Le prix et, pour un entraînement, l'ouverture des inscriptions " \
                  "et la limite de désinscription suivent les règles du club."
      input_schema(properties: SessionWriting::PROPERTIES, required: %w[title session_type start_at terrain_id])
      annotations(**WRITE)

      class << self
        def permission = SessionWriting::PERMISSION

        def execute(context, **arguments)
          attributes = SessionWriting.attributes(arguments)
          attributes[:user_id] ||= context.user.id
          attributes = Sessions::DefaultEndAt.fill(attributes)
          session = Session.new(attributes)
          SessionWriting.invalid(session) unless session.save

          { session: SessionWriting.serialize(session) }
        end
      end
    end
  end
end
