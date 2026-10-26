# frozen_string_literal: true

module Mcp
  module Tools
    # Chiffres du club sur une période : activité, ventes, annulations tardives.
    class ClubStats < Base
      tool_name "club_stats"
      description "Statistiques du club sur une période : sessions et participants par type, " \
                  "ventes de packs (euros), crédits consommés par type de session, annulations tardives. " \
                  "Par défaut : le mois en cours."
      input_schema(properties: date_range_properties("1er du mois", "fin du mois"))
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_dashboard ]

        def execute(_context, from: nil, to: nil)
          start_on = parse_date(from, Date.current.beginning_of_month)
          end_on = parse_date(to, start_on.end_of_month)
          range = day_range(start_on, end_on)

          {
            from: start_on.iso8601,
            to: end_on.iso8601,
            sessions_by_type: Session.held.where(start_at: range).group(:session_type).count,
            confirmed_participants_by_type: Registration.confirmed.joins(:session)
                                                        .where(sessions: { start_at: range })
                                                        .group("sessions.session_type").count,
            packs_revenue_eur: CreditPurchase.where(status: :paid, paid_at: range).sum(:amount_cents) / 100.0,
            packs_revenue_by_type_eur: Reporting::Revenue.new.pack_breakdown_by_type(range),
            credits_consumed_by_session_type: credits_consumed(range),
            late_cancellations_count: LateCancellation.counted.joins(:session).where(sessions: { start_at: range }).count
          }
        end

        private

        # Les paiements de session sont des mouvements négatifs.
        def credits_consumed(range)
          CreditTransaction.payments.joins(:session).where(sessions: { start_at: range })
                           .group("sessions.session_type").sum(:amount)
                           .transform_values(&:-@)
        end
      end
    end
  end
end
