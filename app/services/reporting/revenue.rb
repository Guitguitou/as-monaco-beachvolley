# frozen_string_literal: true

module Reporting
  class Revenue
    def initialize(time_zone: 'Europe/Paris')
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Revenus pour différentes périodes
    def period_revenues
      Reporting::CacheService.fetch('revenue', 'period_revenues', @current_time.to_date) do
        {
          week: revenue_for_period(week_range),
          month: revenue_for_period(month_range),
          year: revenue_for_period(year_range)
        }
      end
    end

    # Breakdown par type d'achat
    def breakdown_by_purchase_type(period_range)
      # Revenus des sessions
      session_revenue = session_revenue_for_period(period_range)
      
      # Revenus des packs
      pack_revenue = pack_revenue_for_period(period_range)
      
      {
        sessions: session_revenue,
        packs: pack_revenue,
        total: session_revenue + pack_revenue
      }
    end

    # Breakdown détaillé des packs par type
    def pack_breakdown_by_type(period_range)
      purchases = CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .joins(:pack)
        .group('packs.pack_type')
        .sum(:amount_cents)

      purchases.transform_values { |cents| cents / 100.0 }
    end

    # Breakdown des sessions par type
    def session_breakdown_by_type(period_range)
      transactions = CreditTransaction
        .payments
        .joins(:session)
        .where(sessions: { start_at: period_range })
        .group('sessions.session_type')
        .sum(:amount)

      # Convertir en montants positifs (les transactions sont négatives)
      transactions.transform_values { |amount| -amount / 100.0 }
    end

    # Évolution des revenus (comparaison avec période précédente)
    def revenue_evolution
      current_week = revenue_for_period(week_range)
      previous_week = revenue_for_period(previous_week_range)
      
      current_month = revenue_for_period(month_range)
      previous_month = revenue_for_period(previous_month_range)

      {
        week: {
          current: current_week,
          previous: previous_week,
          evolution: evolution_percentage(current_week, previous_week)
        },
        month: {
          current: current_month,
          previous: previous_month,
          evolution: evolution_percentage(current_month, previous_month)
        }
      }
    end

    private

    def week_range
      week_start = @current_time.beginning_of_week(:monday)
      week_start..week_start.end_of_week(:monday)
    end

    def previous_week_range
      week_start = @current_time.beginning_of_week(:monday) - 1.week
      week_start..week_start.end_of_week(:monday)
    end

    def month_range
      month_start = @current_time.beginning_of_month
      month_start..month_start.end_of_month
    end

    def previous_month_range
      month_start = @current_time.beginning_of_month - 1.month
      month_start..month_start.end_of_month
    end

    def year_range
      year_start = @current_time.beginning_of_year
      year_start..year_start.end_of_year
    end

    def revenue_for_period(range)
      session_revenue_for_period(range) + pack_revenue_for_period(range)
    end

    def session_revenue_for_period(range)
      # Revenus des sessions (attribués à la date de la session)
      session_revenue = CreditTransaction
        .payments
        .joins(:session)
        .where(sessions: { start_at: range })
        .sum(:amount)

      # Revenus des sessions sans session liée (attribués à la date de création)
      orphan_revenue = CreditTransaction
        .payments
        .where(session_id: nil, created_at: range)
        .sum(:amount)

      # Convertir en montants positifs
      total_cents = -session_revenue - orphan_revenue
      total_cents / 100.0
    end

    def pack_revenue_for_period(range)
      CreditPurchase
        .where(status: :paid, paid_at: range)
        .sum(:amount_cents) / 100.0
    end

    def evolution_percentage(current, previous)
      return 0 if previous.zero?
      ((current - previous) / previous * 100).round(1)
    end
  end
end
