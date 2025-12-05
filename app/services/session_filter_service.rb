# frozen_string_literal: true

# Service pour filtrer les sessions selon différents critères
# Extrait la logique métier depuis Admin::DashboardController
class SessionFilterService
  def initialize(sessions, filters)
    @sessions = sessions.includes(:registrations, :user, :levels)
    @filters = filters
  end

  def call
    apply_date_range_filter
    apply_session_type_filter
    apply_coach_filter
    apply_limit

    @sessions
  end

  private

  def apply_date_range_filter
    case @filters[:date_range]
    when 'week'
      @sessions = @sessions.in_week(week_range.begin)
    when 'month'
      @sessions = @sessions.in_month(month_range.begin)
    when 'year'
      @sessions = @sessions.in_year(year_range.begin)
    end
  end

  def apply_session_type_filter
    case @filters[:session_type]
    when 'entrainement'
      @sessions = @sessions.trainings
    when 'jeu_libre'
      @sessions = @sessions.free_plays
    when 'coaching_prive'
      @sessions = @sessions.private_coachings
    end
  end

  def apply_coach_filter
    return unless @filters[:coach_id].present?

    @sessions = @sessions.where(user_id: @filters[:coach_id])
  end

  def apply_limit
    @sessions = @sessions.ordered_by_start.limit(50)
  end

  def week_range
    DateRangeService.week_range
  end

  def month_range
    DateRangeService.month_range
  end

  def year_range
    DateRangeService.year_range
  end
end

