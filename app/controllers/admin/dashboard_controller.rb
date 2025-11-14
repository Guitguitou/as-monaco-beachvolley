# frozen_string_literal: true
module Admin
  class DashboardController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def index
      @active_tab = params[:tab] || 'overview'
      
      case @active_tab
      when 'overview'
        render_overview_tab
      when 'sessions'
        render_sessions_tab
      when 'finances'
        render_finances_tab
      when 'packs'
        render_packs_tab
      when 'coaches'
        render_coaches_tab
      when 'alerts'
        render_alerts_tab
      else
        render_overview_tab
      end
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user&.admin? || current_user&.financial_manager?
    end

    def render_overview_tab
      kpis_service = Reporting::Kpis.new
      alerts_service = Reporting::Alerts.new
      
      @kpis = kpis_service.week_kpis
      @upcoming_sessions = kpis_service.upcoming_sessions
      @alerts = alerts_service.all_alerts
    end

    def render_sessions_tab
      kpis_service = Reporting::Kpis.new
      alerts_service = Reporting::Alerts.new
      
      @kpis = kpis_service.week_kpis
      @upcoming_sessions = kpis_service.upcoming_sessions
      @alerts = alerts_service.all_alerts
      @filters = session_filters
      @sessions = filtered_sessions
    end

    def render_finances_tab
      revenue_service = Reporting::Revenue.new
      coach_salaries_service = Reporting::CoachSalaries.new
      
      @revenues = revenue_service.period_revenues
      @coach_salaries = {
        week: coach_salaries_service.total_for_period(week_range),
        month: coach_salaries_service.total_for_period(month_range),
        year: coach_salaries_service.total_for_period(year_range)
      }
      @breakdowns = {
        sessions: revenue_service.session_breakdown_by_type(month_range),
        packs: revenue_service.pack_breakdown_by_type(month_range)
      }
    end

    def render_packs_tab
      packs_stats_service = Reporting::PacksStats.new
      
      @monthly_stats = packs_stats_service.monthly_stats_for_current_year
      @yearly_stats = packs_stats_service.yearly_stats
      @pack_types = Pack.pack_types.keys
    end

    def render_coaches_tab
      coach_salaries_service = Reporting::CoachSalaries.new
      coach_stats_service = Reporting::CoachStats.new
      
      @coach_breakdown = coach_salaries_service.breakdown(
        week_range: week_range,
        month_range: month_range,
        year_range: year_range
      )
      
      @upcoming_sessions_by_coach = {}
      @coach_breakdown.each do |coach_data|
        coach = coach_data[:user]
        next unless coach
        
        @upcoming_sessions_by_coach[coach.id] = coach_salaries_service.upcoming_sessions_for_coach(coach)
      end
      
      @monthly_stats = coach_stats_service.monthly_stats_for_current_year
      @yearly_stats = coach_stats_service.yearly_stats
      @coaches = coach_stats_service.active_coaches
    end

    def render_alerts_tab
      alerts_service = Reporting::Alerts.new
      
      @alerts = alerts_service.all_alerts
    end

    def session_filters
      {
        date_range: params[:date_range] || 'week',
        session_type: params[:session_type] || '',
        coach_id: params[:coach_id] || ''
      }
    end

    def filtered_sessions
      sessions = Session.includes(:registrations, :user, :levels)
      
      # Filter by date range using scopes
      case session_filters[:date_range]
      when 'week'
        sessions = sessions.in_week(week_range.begin)
      when 'month'
        sessions = sessions.in_month(month_range.begin)
      when 'year'
        sessions = sessions.in_year(year_range.begin)
      end
      
      # Filter by session type using scopes
      case session_filters[:session_type]
      when 'entrainement'
        sessions = sessions.trainings
      when 'jeu_libre'
        sessions = sessions.free_plays
      when 'coaching_prive'
        sessions = sessions.private_coachings
      end
      
      # Filter by coach
      if session_filters[:coach_id].present?
        sessions = sessions.where(user_id: session_filters[:coach_id])
      end
      
      sessions.ordered_by_start.limit(50)
    end

    def week_range
      current_time = Time.current.in_time_zone('Europe/Paris')
      week_start = current_time.beginning_of_week(:monday)
      week_start..week_start.end_of_week(:monday)
    end

    def month_range
      current_time = Time.current.in_time_zone('Europe/Paris')
      month_start = current_time.beginning_of_month
      month_start..month_start.end_of_month
    end

    def year_range
      current_time = Time.current.in_time_zone('Europe/Paris')
      year_start = current_time.beginning_of_year
      year_start..year_start.end_of_year
    end
  end
end
