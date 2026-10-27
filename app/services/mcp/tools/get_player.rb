# frozen_string_literal: true

module Mcp
  module Tools
    # Parcours d'un joueur : inscriptions, mouvements de crédits, annulations tardives.
    class GetPlayer < Base
      HISTORY_SIZE = 30

      tool_name "get_player"
      description "Détail d'un joueur : niveaux, licence, solde, dernières inscriptions, " \
                  "derniers mouvements de crédits et annulations tardives."
      input_schema(
        properties: { id: { type: "integer", description: "Identifiant du joueur (cf. list_players)." } },
        required: [ "id" ]
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, id:)
          user = User.includes(:balance, :levels).find(id)

          {
            id: user.id,
            name: user.full_name,
            levels: user.levels.map(&:display_name),
            license_type: user.license_type,
            next_season_renewed: user.next_season_renewed,
            balance_credits: user.balance&.amount.to_i,
            roles: user.role_labels,
            licence_payee_at: paris_time(user.activated_at),
            licence_payee: user.activated?,
            dossier_complet: user.dossier_complet?,
            compte_actif: user.peut_reserver?,
            disabled: user.disabled?,
            registrations: registrations(user),
            credit_transactions: credit_transactions(user),
            late_cancellations: late_cancellations(user)
          }
        end

        private

        def registrations(user)
          Registration.where(user_id: user.id).joins(:session).includes(:session)
                      .order("sessions.start_at DESC").limit(HISTORY_SIZE)
                      .map do |registration|
            session = registration.session
            { session_id: session.id, title: session.title, session_type: session.session_type,
              start_at: paris_time(session.start_at), status: registration.status }
          end
        end

        def credit_transactions(user)
          CreditTransaction.where(user_id: user.id).order(created_at: :desc).limit(HISTORY_SIZE).map do |transaction|
            { at: paris_time(transaction.created_at), type: transaction.transaction_type,
              amount_credits: transaction.amount, session_id: transaction.session_id }
          end
        end

        def late_cancellations(user)
          LateCancellation.where(user_id: user.id).includes(:session).order(created_at: :desc).map do |cancellation|
            { at: paris_time(cancellation.created_at), session_id: cancellation.session_id,
              title: cancellation.session.title, start_at: paris_time(cancellation.session.start_at),
              excused: cancellation.excused }
          end
        end
      end
    end
  end
end
