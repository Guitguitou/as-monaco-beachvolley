# frozen_string_literal: true

# Service to filter sessions based on various criteria
class SessionFilterService
  def initialize(sessions_scope, filters)
    @sessions = sessions_scope
    @filters = filters
  end

  def call
    apply_coach_filter
    apply_period_filter
    apply_date_range_filter
    @sessions.order(start_at: :desc)
  end

  private

  def apply_coach_filter
    return unless @filters[:coach_id].present?

    @sessions = @sessions.where(user_id: @filters[:coach_id])
  end

  def apply_period_filter
    return if @filters[:period].blank?

    range = period_range(@filters[:period])
    @sessions = @sessions.where(start_at: range) if range
  end

  def apply_date_range_filter
    return if @filters[:period].present?

    from = parse_time(@filters[:start_at_from])
    to = parse_time(@filters[:start_at_to])

    if from && to
      @sessions = @sessions.where(start_at: from..to)
    elsif from
      @sessions = @sessions.where("start_at >= ?", from)
    elsif to
      @sessions = @sessions.where("start_at <= ?", to)
    end
  end

  def period_range(period)
    case period
    when "week"
      Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
    when "month"
      Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
    when "year"
      Time.zone.now.beginning_of_year..Time.zone.now.end_of_year
    end
  end

  def parse_time(time_string)
    return nil unless time_string.presence

    Time.zone.parse(time_string)
  rescue ArgumentError
    nil
  end
end
