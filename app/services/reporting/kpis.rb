# frozen_string_literal: true

module Reporting
  class Kpis
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # KPIs pour la semaine en cours (Lun→Dim)
    def week_kpis
      Reporting::CacheService.fetch("kpis", "week_kpis", @current_time.to_date) do
        week_range = week_start..week_end

        {
          trainings_count: trainings_count(week_range),
          free_plays_count: free_plays_count(week_range),
          private_coachings_count: private_coachings_count(week_range),
          late_cancellations_count: late_cancellations_count(week_range),
          revenue: revenue_for_period(week_range),
          coach_salaries: coach_salaries_for_period(week_range),
          net_profit: net_profit_for_period(week_range)
        }
      end
    end

    # Sessions à venir (7 prochains jours)
    def upcoming_sessions(limit: 7)
      upcoming_range = @current_time..(@current_time + 7.days)

      {
        "entrainement" => upcoming_trainings(upcoming_range, limit),
        "jeu_libre" => upcoming_free_plays(upcoming_range, limit),
        "coaching_prive" => upcoming_private_coachings(upcoming_range, limit)
      }
    end

    # Sessions avec alertes de capacité
    def capacity_alerts
      upcoming_range = @current_time..(@current_time + 7.days)
      sessions = Session.upcoming
                       .where(start_at: upcoming_range)
                       .includes(:registrations, :user)
                       .where.not(max_players: nil)

      sessions.select do |session|
        next false unless session.max_players.present?

        capacity_ratio = session.registrations.confirmed.count.to_f / session.max_players
        capacity_ratio < 0.4 || capacity_ratio >= 0.9
      end
    end

    # Désinscriptions hors délai récentes
    def recent_late_cancellations(limit: 10)
      LateCancellation.for_trainings
                      .with_associations
                      .recent(limit)
    end

    def revenue_for_period(range)
      # CA = Achats de packs de crédits uniquement
      CreditPurchase
        .where(status: :paid, paid_at: range)
        .sum(:amount_cents) / 100.0
    end

    def coach_salaries_for_period(range)
      Reporting::CoachSalaries.new.total_for_period(range)
    end

    def net_profit_for_period(range)
      revenue_for_period(range) - coach_salaries_for_period(range)
    end

    private

    def week_start
      @current_time.beginning_of_week(:monday)
    end

    def week_end
      @current_time.end_of_week(:monday)
    end

    def trainings_count(range)
      Session.trainings_in_range(range.begin, range.end).count
    end

    def free_plays_count(range)
      Session.free_plays_in_range(range.begin, range.end).count
    end

    def private_coachings_count(range)
      Session.private_coachings_in_range(range.begin, range.end).count
    end

    def late_cancellations_count(range)
      LateCancellation.joins(:session)
                      .where(sessions: { start_at: range })
                      .count
    end

    def upcoming_trainings(range, limit)
      Session.trainings
             .where(start_at: range)
             .includes(:registrations, :levels, :user)
             .ordered_by_start
             .limit(limit)
    end

    def upcoming_free_plays(range, limit)
      Session.free_plays
             .where(start_at: range)
             .includes(:registrations, :user)
             .ordered_by_start
             .limit(limit)
    end

    def upcoming_private_coachings(range, limit)
      Session.private_coachings
             .where(start_at: range)
             .includes(:registrations, :user)
             .ordered_by_start
             .limit(limit)
    end
  end
end
