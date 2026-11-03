# frozen_string_literal: true

module Mcp
  module Tools
    # Supprime une session saisie par erreur : les inscrits sont remboursés et
    # prévenus (cf. GLOSSARY.md, « Suppression de séance »).
    class DeleteSession < Base
      tool_name "delete_session"
      description "Supprime une session saisie par erreur (admins uniquement) : rembourse et prévient les inscrits. " \
                  "Irréversible."
      input_schema(properties: { id: { type: "integer" } }, required: %w[id])
      annotations(**WRITE, destructive_hint: true, idempotent_hint: true)

      class << self
        def permission = SessionWriting::PERMISSION

        def execute(_context, id:)
          session = Session.find(id)
          Sessions::DestroySessionService.call(session:)

          { deleted_session_id: id }
        end
      end
    end
  end
end
