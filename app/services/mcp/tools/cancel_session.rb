# frozen_string_literal: true

module Mcp
  module Tools
    # Annule une session avec son motif, comme le bouton « Annuler » de l'app :
    # elle reste connue du club, les inscrits sont remboursés et prévenus
    # (cf. GLOSSARY.md, « Séance annulée »).
    class CancelSession < Base
      tool_name "cancel_session"
      description "Annule une session (admins uniquement) avec un motif : rembourse et prévient les inscrits " \
                  "(push + email). La session reste visible comme annulée ; à préférer à delete_session pour une séance réelle."
      input_schema(
        properties: {
          id: { type: "integer" },
          reason: { type: "string", enum: Session::MANUAL_CANCELLATION_REASON_LABELS.keys,
                    description: Session::MANUAL_CANCELLATION_REASON_LABELS.map { |key, label| "#{key} : #{label}" }.join(", ") }
        },
        required: %w[id reason]
      )
      annotations(**WRITE, destructive_hint: true, idempotent_hint: true)

      class << self
        def permission = SessionWriting::PERMISSION

        def execute(_context, id:, reason:)
          session = Session.find(id)
          raise ArgumentError, "Session déjà annulée." if session.cancelled?

          result = Sessions::CancelSessionService.call(session:, reason:)
          { session: SessionWriting.serialize(session.reload), cancellation_reason: reason,
            notified_players_count: result[:notified_users].size }
        end
      end
    end
  end
end
