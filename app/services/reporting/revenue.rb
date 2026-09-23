# frozen_string_literal: true

module Reporting
  class Revenue
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # CA (Chiffre d'Affaires) pour différentes périodes
    def period_revenues
      Reporting::CacheService.fetch("revenue", "period_revenues", @current_time.to_date) do
        {
          week: revenue_for_period(week_range),
          month: revenue_for_period(month_range),
          year: revenue_for_period(year_range)
        }
      end
    end

    # Breakdown détaillé des packs de crédits par type
    def pack_breakdown_by_type(period_range)
      purchases = CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .joins(:pack)
        .group("packs.pack_type")
        .sum(:amount_cents)

      purchases.transform_values { |cents| cents / 100.0 }
    end

    # Breakdown des revenus par type de session (pour information visuelle)
    def session_breakdown_by_type(period_range)
      transactions = CreditTransaction
        .payments
        .joins(:session)
        .where(sessions: { start_at: period_range })
        .group("sessions.session_type")
        .sum(:amount)

      # Convertir en montants positifs (les transactions sont négatives)
      transactions.transform_values { |amount| -amount / 100.0 }
    end

    private

    def week_range
      week_start = @current_time.beginning_of_week(:monday)
      week_start..week_start.end_of_week(:monday)
    end

    def month_range
      month_start = @current_time.beginning_of_month
      month_start..month_start.end_of_month
    end

    def year_range
      year_start = @current_time.beginning_of_year
      year_start..year_start.end_of_year
    end

    def revenue_for_period(range)
      credit_packs_revenue_for_period(range) +
      licenses_revenue_for_period(range) +
      stages_revenue_for_period(range)
    end

    def credit_packs_revenue_for_period(range)
      CreditPurchase
        .where(status: :paid, paid_at: range)
        .sum(:amount_cents) / 100.0
    end

    def licenses_revenue_for_period(range)
      # TODO: Implémenter quand le système de licences sera créé
      0.0
    end

    def stages_revenue_for_period(range)
      # TODO: Implémenter quand le système de stages sera créé
      0.0
    end
  end
end
