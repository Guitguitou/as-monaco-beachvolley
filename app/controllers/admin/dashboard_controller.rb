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
        week: coach_salaries_service.total_for_period(DateRangeService.week_range),
        month: coach_salaries_service.total_for_period(DateRangeService.month_range),
        year: coach_salaries_service.total_for_period(DateRangeService.year_range)
      }
      @breakdowns = {
        sessions: revenue_service.session_breakdown_by_type(DateRangeService.month_range),
        packs: revenue_service.pack_breakdown_by_type(DateRangeService.month_range)
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
        week_range: DateRangeService.week_range,
        month_range: DateRangeService.month_range,
        year_range: DateRangeService.year_range
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
      SessionFilterService.new(Session.all, session_filters).call
    end

  end
end
