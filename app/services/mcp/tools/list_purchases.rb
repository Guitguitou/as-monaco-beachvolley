# frozen_string_literal: true

module Mcp
  module Tools
    # Achats payés en euros (Sherlock's), comme l'Historique achats de l'admin.
    class ListPurchases < Base
      MAX_RESULTS = 300

      tool_name "list_purchases"
      description "Liste les achats en euros (packs de crédits, licences, stages, inscriptions tournoi, équipements) " \
                  "sur une période, avec le pack, le montant, les crédits obtenus et le statut du paiement. " \
                  "Donne aussi les totaux de la période (encaissé par type de pack, nombre par statut). " \
                  "Par défaut : le mois en cours, tous statuts."
      input_schema(
        properties: {
          from: { type: "string", format: "date", description: "Début inclus (AAAA-MM-JJ), sur la date de création de l'achat. Défaut : 1er du mois." },
          to: { type: "string", format: "date", description: "Fin incluse (AAAA-MM-JJ). Défaut : fin du mois." },
          status: { type: "string", enum: CreditPurchase.statuses.keys },
          pack_type: { type: "string", enum: CreditPurchase::REPORTING_PACK_TYPES },
          player_id: { type: "integer", description: "Ne garder que les achats de ce joueur (cf. list_players)." }
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, CreditPurchase ]

        def execute(_context, from: nil, to: nil, status: nil, pack_type: nil, player_id: nil)
          start_on = parse_date(from, Date.current.beginning_of_month)
          end_on = parse_date(to, start_on.end_of_month)
          purchases = scope(start_on, end_on, status, pack_type, player_id)
          listed = purchases.includes(:user, :pack).order(created_at: :desc).limit(MAX_RESULTS).to_a

          {
            from: start_on.iso8601,
            to: end_on.iso8601,
            totals: totals(purchases),
            truncated: listed.size == MAX_RESULTS,
            purchases: listed.map { |purchase| serialize(purchase) }
          }
        end

        private

        def scope(start_on, end_on, status, pack_type, player_id)
          purchases = CreditPurchase.left_joins(:pack)
                                    .where(created_at: start_on.in_time_zone.beginning_of_day..end_on.in_time_zone.end_of_day)
          purchases = purchases.where(status:) if status.present?
          purchases = purchases.where(CreditPurchase::PACK_TYPE_SQL.eq(pack_type)) if pack_type.present?
          purchases = purchases.where(user_id: player_id) if player_id.present?
          purchases
        end

        def totals(purchases)
          paid = purchases.paid_status
          {
            paid_eur: paid.sum(:amount_cents) / 100.0,
            paid_by_pack_type_eur: paid.group(CreditPurchase::PACK_TYPE_SQL).sum(:amount_cents)
                                       .transform_values { |cents| cents / 100.0 },
            count_by_status: purchases.group(:status).count
          }
        end

        def serialize(purchase)
          {
            id: purchase.id,
            created_at: paris_time(purchase.created_at),
            paid_at: paris_time(purchase.paid_at),
            player_id: purchase.user_id,
            player: purchase.user.full_name,
            pack: purchase.pack&.name,
            pack_type: purchase.pack&.pack_type || CreditPurchase::OTHER_PACK_TYPE,
            amount_eur: purchase.amount_eur,
            credits: purchase.credits,
            status: purchase.status,
            reference: purchase.sherlock_transaction_reference
          }
        end
      end
    end
  end
end
