# frozen_string_literal: true

module Reporting
  class Alerts
    def initialize(time_zone: 'Europe/Paris')
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
    def late_cancellation_alerts
      recent_range = @current_time - 7.days..@current_time
      
      LateCancellation
        .for_trainings
        .where(created_at: recent_range)
        .includes(:user, :session)
        .order(created_at: :desc)
        .limit(20)
    end

    # Alertes de capacité (sessions presque pleines ou en sous-capacité)
    def capacity_alerts
      upcoming_range = @current_time..(@current_time + 7.days)
      
      sessions = Session
        .upcoming
        .where(start_at: upcoming_range)
        .includes(:registrations, :user)
        .where.not(max_players: nil)

      sessions.select do |session|
        next false unless session.max_players.present?
        
        capacity_ratio = session.registrations.confirmed.count.to_f / session.max_players
        
        # Sous-capacité (< 40%) ou presque plein (> 90%)
        capacity_ratio < 0.4 || capacity_ratio > 0.9
      end
    end

    # Alertes de faible participation
    def low_attendance_alerts
      upcoming_range = @current_time..(@current_time + 3.days)
      
      Session
        .upcoming
        .where(start_at: upcoming_range)
        .includes(:registrations, :user)
        .where.not(max_players: nil)
        .select do |session|
          next false unless session.max_players.present?
          
          capacity_ratio = session.registrations.confirmed.count.to_f / session.max_players
          capacity_ratio < 0.3 # Moins de 30% de remplissage
        end
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

    # Compteurs d'alertes
    def alert_counts
      {
        late_cancellations: late_cancellation_alerts.count,
        capacity_alerts: capacity_alerts.count,
        low_attendance: low_attendance_alerts.count,
        upcoming_sessions: upcoming_sessions_alerts.count
      }
    end

    # Alertes critiques (nécessitent une action immédiate)
    def critical_alerts
      {
        late_cancellations_today: late_cancellations_today,
        sessions_starting_soon: sessions_starting_soon,
        empty_sessions: empty_sessions
      }
    end

    private

    def late_cancellations_today
      today_range = @current_time.beginning_of_day..@current_time.end_of_day
      
      LateCancellation
        .for_trainings
        .where(created_at: today_range)
        .includes(:user, :session)
        .order(created_at: :desc)
    end

    def sessions_starting_soon
      # Sessions dans les 2 prochaines heures
      soon_range = @current_time..(@current_time + 2.hours)
      
      Session
        .upcoming
        .where(start_at: soon_range)
        .includes(:registrations, :user)
        .order(:start_at)
    end

    def empty_sessions
      # Sessions à venir sans inscription
      upcoming_range = @current_time..(@current_time + 7.days)
      
      Session
        .upcoming
        .where(start_at: upcoming_range)
        .left_joins(:registrations)
        .where(registrations: { id: nil })
        .includes(:user)
        .order(:start_at)
    end
  end
end
