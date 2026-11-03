# frozen_string_literal: true

module Mcp
  module Tools
    # Modifie une session, comme l'édition de l'admin : deadlines décalées et
    # entraînement rééquilibré si ses places ou ses niveaux changent.
    class UpdateSession < Base
      tool_name "update_session"
      description "Modifie une session (admins uniquement). Seuls les champs fournis changent."
      input_schema(properties: { id: { type: "integer" }, **SessionWriting::PROPERTIES }, required: %w[id])
      annotations(**WRITE, idempotent_hint: true)

      class << self
        def permission = SessionWriting::PERMISSION

        def execute(_context, id:, **arguments)
          session = Session.find(id)
          result = Sessions::AdminUpdate.new(
            session:, attributes: SessionWriting.attributes(arguments), level_priorities: SessionWriting.level_priorities(arguments),
            levels_submitted: arguments.key?(:level_ids), scope: "this"
          ).call { nil }
          raise ArgumentError, "Session invalide : #{session.errors.full_messages.to_sentence}" unless result.saved?

          { session: SessionWriting.serialize(session.reload) }
        end
      end
    end
  end
end
