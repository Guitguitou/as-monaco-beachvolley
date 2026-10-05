# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    before_action :require_admin_or_financial_manager!

    TABS = %w[overview sessions packs coaches alerts].freeze

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

    def render_packs_tab
      packs_stats_service = Reporting::PacksStats.new

      @monthly_stats = packs_stats_service.monthly_stats_for_current_year
      @yearly_stats = packs_stats_service.yearly_stats
      @pack_types = CreditPurchase::REPORTING_PACK_TYPES
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

    def current_ranges = SessionsPeriod.current_ranges
  end
end
