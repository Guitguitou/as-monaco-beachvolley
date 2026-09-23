# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    before_action :require_admin_or_financial_manager!

    TABS = %w[overview sessions finances packs coaches alerts].freeze

    def index
      @active_tab = TABS.include?(params[:tab]) ? params[:tab] : "overview"
      send("render_#{@active_tab}_tab")
    end

    private

    def render_overview_tab
      kpis_service = Reporting::Kpis.new
      @kpis = kpis_service.week_kpis
      @upcoming_sessions = kpis_service.upcoming_sessions
      @alerts = Reporting::Alerts.new.all_alerts

      # Inscrits par mois (jeu libre + entrainement) avec navigation
      @stats_year = (params[:stats_year].presence || Time.current.year).to_i
      @stats_month = (params[:stats_month].presence || Time.current.month).to_i.clamp(1, 12)
      participants = kpis_service.monthly_participants(Time.find_zone("Europe/Paris").local(@stats_year, @stats_month))
      @participants_jeu_libre = participants[:jeu_libre]
      @participants_entrainement = participants[:entrainement]
    end

    def render_sessions_tab
      @kpis = Reporting::Kpis.new.week_kpis
      @alerts = Reporting::Alerts.new.all_alerts
      @sessions_tab = SessionsTab.new(params)
    end

    def render_finances_tab
      revenue_service = Reporting::Revenue.new
      @revenues = revenue_service.period_revenues
      @coach_salaries = current_ranges.transform_values { |range| Reporting::CoachSalaries.new.total_for_period(range) }
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
      coach_stats_service = Reporting::CoachStats.new
      @coach_breakdown = Reporting::CoachSalaries.new.breakdown(current_ranges)
      @upcoming_sessions_by_coach = @coach_breakdown.to_h do |row|
        [ row[:user].id, Reporting::CoachPayroll.new(row[:user]).upcoming_sessions ]
      end

      @monthly_stats = coach_stats_service.monthly_stats_for_current_year
      @yearly_stats = coach_stats_service.yearly_stats
      @coaches = coach_stats_service.active_coaches
    end

    def render_alerts_tab
      @alerts = Reporting::Alerts.new.all_alerts
    end

    def current_ranges
      %w[week month year].to_h { |period| [ period.to_sym, SessionsPeriod.new(period, nil).range ] }
    end

    def month_range = current_ranges[:month]
  end
end
