# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def index
      @active_tab = params[:tab] || "overview"

      case @active_tab
      when "overview"
        render_overview_tab
      when "sessions"
        render_sessions_tab
      when "finances"
        render_finances_tab
      when "packs"
        render_packs_tab
      when "coaches"
        render_coaches_tab
      when "alerts"
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

      # Inscrits par mois (jeu libre + entrainement) avec navigation
      @stats_year = (params[:stats_year].presence || Time.current.year).to_i
      @stats_month = (params[:stats_month].presence || Time.current.month).to_i.clamp(1, 12)
      stats_month_start = Time.zone.parse("#{@stats_year}-#{@stats_month}-01").in_time_zone("Europe/Paris").beginning_of_month
      participants = kpis_service.monthly_participants(stats_month_start)
      @participants_jeu_libre = participants[:jeu_libre]
      @participants_entrainement = participants[:entrainement]
    end

    def render_sessions_tab
      kpis_service = Reporting::Kpis.new
      alerts_service = Reporting::Alerts.new
      @kpis = kpis_service.week_kpis
      @alerts = alerts_service.all_alerts

      @sessions_sub_tab = params[:session_type].to_s.presence || "upcoming"

      if @sessions_sub_tab == "upcoming"
        @upcoming_sessions_flat = Session.upcoming
          .where("start_at >= ?", Time.current)
          .includes(:registrations, :user)
          .ordered_by_start
          .limit(100)
      else
        period = SessionsPeriod.new(params[:period].presence, params[:period_anchor])
        @sessions_period = period.name
        @sessions_by_type = sessions_for_type_and_range(@sessions_sub_tab, period.range)
        @period_label = period.label
        base = { tab: "sessions", session_type: @sessions_sub_tab, period: period.name }
        @prev_period_params = base.merge(period_anchor: period.previous_anchor)
        @next_period_params = base.merge(period_anchor: period.next_anchor)
      end
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

    def sessions_for_type_and_range(session_type, range)
      scope = Session.where(start_at: range).includes(:registrations, :user)
      scope = case session_type
      when "entrainement" then scope.trainings
      when "jeu_libre" then scope.free_plays
      when "coaching_prive" then scope.private_coachings
      when "tournoi" then scope.where(session_type: "tournoi")
      when "stage" then scope.where(session_type: "stage")
      else scope
      end
      scope.order(start_at: :desc)
    end

    def week_range = SessionsPeriod.new("week", nil).range

    def month_range = SessionsPeriod.new("month", nil).range

    def year_range = SessionsPeriod.new("year", nil).range
  end
end
