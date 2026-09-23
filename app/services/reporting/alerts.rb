# frozen_string_literal: true

module Reporting
  class Alerts
    LateCancellationSummary = Struct.new(
      :user,
      :cancellations_count,
      :last_cancelled_at,
      keyword_init: true
    )

    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Toutes les alertes
    def all_alerts
      {
        late_cancellations: late_cancellation_alerts,
        capacity_alerts: capacity_alerts,
        low_attendance: low_attendance_alerts,
        upcoming_sessions: upcoming_sessions_alerts
      }
    end

    # Alertes de désinscriptions hors délai
    def late_cancellation_alerts(limit: 20)
      grouped = LateCancellation
        .for_trainings
        .select("late_cancellations.user_id AS user_id, COUNT(*) AS cancellations_count, MAX(late_cancellations.created_at) AS last_cancelled_at")
        .group("late_cancellations.user_id")
        .order("cancellations_count DESC, last_cancelled_at DESC")
        .limit(limit)

      users_by_id = User.where(id: grouped.map(&:user_id)).index_by(&:id)

      grouped.map do |row|
        LateCancellationSummary.new(
          user: users_by_id[row.user_id],
          cancellations_count: row.cancellations_count.to_i,
          last_cancelled_at: row.last_cancelled_at
        )
      end
    end

    # Sessions de la semaine en sous-capacité (< 40 %) ou presque pleines (> 90 %).
    def capacity_alerts
      sessions_filled_within(7.days) { |ratio| ratio < 0.4 || ratio > 0.9 }
    end

    # Sessions des 3 prochains jours remplies à moins de 30 %.
    def low_attendance_alerts
      sessions_filled_within(3.days) { |ratio| ratio < 0.3 }
    end

    # Sessions à venir nécessitant une attention
    def upcoming_sessions_alerts
      upcoming_range = @current_time..(@current_time + 2.days)

      Session
        .upcoming
        .where(start_at: upcoming_range)
        .includes(:registrations, :user, :levels)
        .order(:start_at)
    end

    private

    def sessions_filled_within(duration)
      Session.upcoming.where(start_at: @current_time..(@current_time + duration)).where.not(max_players: nil)
        .includes(:registrations, :user)
        .select { |session| yield(session.registrations.confirmed.count.to_f / session.max_players) }
    end
  end
end
