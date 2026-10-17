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
                  "Donne aussi le total et le nombre de mouvements par type. Par défaut : le mois en cours."
      input_schema(
        properties: {
          from: { type: "string", format: "date", description: "Début inclus (AAAA-MM-JJ). Défaut : 1er du mois." },
          to: { type: "string", format: "date", description: "Fin incluse (AAAA-MM-JJ). Défaut : fin du mois." },
          transaction_type: { type: "string", enum: CreditTransaction.transaction_types.keys },
          player_id: { type: "integer", description: "Ne garder que les mouvements de ce joueur (cf. list_players)." },
          session_id: { type: "integer", description: "Ne garder que les mouvements liés à cette session (cf. list_sessions)." }
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, from: nil, to: nil, **filters)
          period = month_period(from, to)
          transactions = scope(period, **filters)
          listed, truncated = capped(transactions.includes(:user, :session).order(created_at: :desc), MAX_RESULTS)

          {
            **period_payload(period),
            totals_by_type: totals(transactions),
            truncated:,
            transactions: listed.map { |transaction| serialize(transaction) }
          }
        end

        private

        def scope(period, transaction_type: nil, player_id: nil, session_id: nil)
          transactions = CreditTransaction.where(created_at: day_bounds(period))
          transactions = transactions.where(transaction_type:) if transaction_type.present?
          transactions = transactions.where(user_id: player_id) if player_id.present?
          transactions = transactions.where(session_id:) if session_id.present?
          transactions
        end

        def totals(transactions)
          by_type = transactions.group(:transaction_type)
          sums = by_type.sum(:amount)
          counts = by_type.count
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
