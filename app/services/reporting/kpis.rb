# frozen_string_literal: true

module Reporting
  class Kpis
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    UPCOMING_TYPES = %w[entrainement jeu_libre coaching_prive].freeze

    # KPIs pour la semaine en cours (Lun→Dim)
    def week_kpis
      Reporting::CacheService.fetch("kpis", "week_kpis", @current_time.to_date) do
        range = @current_time.beginning_of_week(:monday)..@current_time.end_of_week(:monday)
        counts = Session.where(start_at: range).group(:session_type).count
        revenue = revenue_for_period(range)
        salaries = Reporting::CoachSalaries.new.total_for_period(range)
        {
          trainings_count: counts["entrainement"].to_i,
          free_plays_count: counts["jeu_libre"].to_i,
          private_coachings_count: counts["coaching_prive"].to_i,
          late_cancellations_count: LateCancellation.joins(:session).count,
          revenue: revenue,
          coach_salaries: salaries,
          net_profit: revenue - salaries
        }
      end
    end

    # Nombre total de personnes inscrites (confirmed) par type sur un mois donné
    def monthly_participants(month_start)
      counts = Registration.confirmed.joins(:session)
        .where(sessions: { start_at: month_start..month_start.end_of_month }).group("sessions.session_type").count
      { jeu_libre: counts["jeu_libre"].to_i, entrainement: counts["entrainement"].to_i }
    end

    # Sessions à venir (7 prochains jours), par type
    def upcoming_sessions(limit: 7)
      range = @current_time..(@current_time + 7.days)
      UPCOMING_TYPES.index_with do |type|
        Session.where(session_type: type, start_at: range).includes(:registrations, :levels, :user).ordered_by_start.limit(limit)
      end
    end

    private

    # CA = Achats de packs de crédits uniquement
    def revenue_for_period(range)
      CreditPurchase.where(status: :paid, paid_at: range).sum(:amount_cents) / 100.0
    end
  end
end
