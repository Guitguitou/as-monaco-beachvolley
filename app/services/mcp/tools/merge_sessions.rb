# frozen_string_literal: true

module Mcp
  module Tools
    # Fusion de séances, comme le bouton « Fusionner » de l'app (cf. GLOSSARY.md,
    # ADR 0005) : la séance conservée reçoit groupes et inscrits de l'autre.
    class MergeSessions < Base
      tool_name "merge_sessions"
      description "Fusionne deux entraînements au même créneau et au même prix (admins uniquement) : la séance conservée " \
                  "reçoit les groupes et les inscrits de la séance absorbée, avec le coach et la capacité choisis. " \
                  "La séance absorbée est annulée au motif « fusionnée », sans remboursement. Irréversible."
      input_schema(
        properties: {
          kept_session_id: { type: "integer", description: "Séance conservée." },
          absorbed_session_id: { type: "integer", description: "Séance absorbée, annulée après transfert." },
          coach_id: { type: "integer", description: "Coach qui encadre la séance fusionnée." },
          max_players: { type: "integer", description: "Capacité de la séance fusionnée (au moins les confirmés cumulés)." }
        },
        required: %w[kept_session_id absorbed_session_id coach_id max_players]
      )
      annotations(**WRITE, destructive_hint: true)

      class << self
        def permission = SessionWriting::PERMISSION

        def execute(_context, kept_session_id:, absorbed_session_id:, coach_id:, max_players:)
          absorbed = Session.find(absorbed_session_id)
          transferred_players_count = absorbed.registrations.count
          kept = Sessions::MergeService.call(kept: Session.find(kept_session_id), absorbed:,
                                             coach: User.find(coach_id), max_players:)
          { session: SessionWriting.serialize(kept.reload), transferred_players_count: }
        rescue Sessions::MergeService::Error => e
          raise ArgumentError, e.message
        end
      end
    end
  end
end
