# frozen_string_literal: true

module Mcp
  module Tools
    # Mouvements de crédits : achats crédités, paiements de sessions,
    # remboursements et ajustements manuels.
    class ListCreditTransactions < Base
      MAX_RESULTS = 300

      tool_name "list_credit_transactions"
      description "Liste les mouvements de crédits sur une période : crédits ajoutés après achat (purchase), " \
                  "paiements de sessions (négatifs), remboursements (refund) et ajustements manuels. " \
                  "Donne aussi le total et le nombre de mouvements par type. Par défaut : le mois en cours ; " \
                  "avec updated_since sans from/to, toutes périodes. #{PAGINATION_NOTE}"
      input_schema(
        properties: {
          from: { type: "string", format: "date", description: "Début inclus (AAAA-MM-JJ). Défaut : 1er du mois." },
          to: { type: "string", format: "date", description: "Fin incluse (AAAA-MM-JJ). Défaut : fin du mois." },
          transaction_type: { type: "string", enum: CreditTransaction.transaction_types.keys },
          player_id: { type: "integer", description: "Ne garder que les mouvements de ce joueur (cf. list_players)." },
          session_id: { type: "integer", description: "Ne garder que les mouvements liés à cette session (cf. list_sessions)." },
          **PAGINATION_PROPERTIES
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, from: nil, to: nil, transaction_type: nil, player_id: nil, session_id: nil, cursor: nil,
                    updated_since: nil)
          period = period(from, to, updated_since)
          transactions = scope(period, transaction_type, player_id, session_id)
          page = paginate(transactions.includes(:user, :session), cursor, updated_since)

          {
            from: period&.first&.iso8601,
            to: period&.last&.iso8601,
            totals_by_type: totals(transactions),
            next_cursor: page[:next_cursor],
            transactions: page[:records].map { |transaction| serialize(transaction) }
          }
        end

        private

        def scope(period, transaction_type, player_id, session_id)
          transactions = CreditTransaction.all
          transactions = transactions.where(created_at: period.first.in_time_zone.beginning_of_day..period.last.in_time_zone.end_of_day) if period
          transactions = transactions.where(transaction_type:) if transaction_type.present?
          transactions = transactions.where(user_id: player_id) if player_id.present?
          transactions = transactions.where(session_id:) if session_id.present?
          transactions
        end

        def totals(transactions)
          sums = transactions.group(:transaction_type).sum(:amount)
          counts = transactions.group(:transaction_type).count
          counts.to_h { |type, count| [ type, { count:, amount_credits: sums.fetch(type, 0) } ] }
        end

        def serialize(transaction)
          session = transaction.session
          {
            id: transaction.id,
            at: paris_time(transaction.created_at),
            type: transaction.transaction_type,
            amount_credits: transaction.amount,
            player_id: transaction.user_id,
            player: transaction.user.full_name,
            session_id: session&.id,
            session: session && { title: session.title, session_type: session.session_type,
                                  start_at: paris_time(session.start_at) }
          }
        end
      end
    end
  end
end
