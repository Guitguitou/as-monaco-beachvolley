# frozen_string_literal: true

module Admin
  class DashboardPresenter
  def initialize
    @current_time = Time.zone.now
  end

  def upcoming_trainings_for_week(week_start)
    Session.trainings.in_week(week_start).ordered_by_start
  end

  def upcoming_free_plays
    Session.free_plays.upcoming.ordered_by_start
  end

  def upcoming_private_coachings
    Session.private_coachings.upcoming.ordered_by_start
  end

  def current_month_revenue
    month_range = @current_time.beginning_of_month..@current_time.end_of_month
    # Get all revenue-related transactions (payments and refunds)
    revenue_transactions = CreditTransaction.revenue_transactions.in_period(month_range.first, month_range.last)
    
    # Calculate net revenue: payments (negative amounts) - refunds (positive amounts)
    # Payments are negative, refunds are positive, so we negate the sum to get positive revenue
    # Convert credits to euros (100 credits = 1€)
    monthly_sum = revenue_transactions.sum(:amount)
    -monthly_sum / 100.0
  end

  def coach_salary_for_period(range)
    trainings = Session.trainings.where(start_at: range)
    by_coach_counts = trainings.group(:user_id).count
    users = User.where(id: by_coach_counts.keys).index_by(&:id)
    total_cents = by_coach_counts.sum do |user_id, count|
      (users[user_id]&.salary_per_training_cents || 0) * count
    end
    total_cents / 100
  end

  def coach_salary_breakdown(week_range:, month_range:, year_range:)
    trainings = Session.trainings
    week_counts  = trainings.where(start_at: week_range).group(:user_id).count
    month_counts = trainings.where(start_at: month_range).group(:user_id).count
    year_counts  = trainings.where(start_at: year_range).group(:user_id).count

    user_ids = (week_counts.keys + month_counts.keys + year_counts.keys).uniq
    users = User.where(id: user_ids).index_by(&:id)

    breakdown = user_ids.map do |uid|
      user = users[uid]
      spt = user&.salary_per_training_cents.to_i
      wc = week_counts[uid].to_i
      mc = month_counts[uid].to_i
      yc = year_counts[uid].to_i
      {
        user: user,
        week_count: wc,
        week_amount: (spt * wc) / 100.0,
        month_count: mc,
        month_amount: (spt * mc) / 100.0,
        year_count: yc,
        year_amount: (spt * yc) / 100.0
      }
    end

    breakdown.sort_by { |h| -h[:month_amount] }
  end

  def recent_late_cancellations
    LateCancellation.for_trainings.with_associations.recent
  end

  def late_cancellation_counts
    LateCancellation.for_trainings.group(:user_id).count
  end

  def week_start
    @current_time.beginning_of_week
  end

  def month_start
    @current_time.beginning_of_month
  end

  def year_start
    @current_time.beginning_of_year
  end

  # Charges et revenus
  def weekly_charges
    week_range = week_start..(week_start + 7.days)
    coach_salaries = coach_salary_for_period(week_range)
    refunds = weekly_refunds
    coach_salaries + refunds
  end

  def monthly_charges
    month_range = month_start..month_start.end_of_month
    coach_salaries = coach_salary_for_period(month_range)
    refunds = monthly_refunds
    coach_salaries + refunds
  end

  def weekly_revenue
    week_range = week_start..(week_start + 7.days)
    weekly_payments = CreditTransaction.payments.in_period(week_range.first, week_range.last).sum(:amount)
    # Convert credits to euros (100 credits = 1€) and make revenue positive
    -weekly_payments / 100.0
  end

  def monthly_revenue
    month_range = month_start..month_start.end_of_month
    monthly_payments = CreditTransaction.payments.in_period(month_range.first, month_range.last).sum(:amount)
    # Convert credits to euros (100 credits = 1€) and make revenue positive
    -monthly_payments / 100.0
  end

  def weekly_net_profit
    weekly_revenue - weekly_charges
  end

  def monthly_net_profit
    monthly_revenue - monthly_charges
  end

  def charges_breakdown(period_range)
    coach_salaries = coach_salary_for_period(period_range)
    refunds = refunds_for_period(period_range)
    
    {
      coach_salaries: coach_salaries,
      refunds: refunds,
      total: coach_salaries + refunds
    }
  end

  def revenue_breakdown(period_range)
    payments = CreditTransaction.payments.in_period(period_range.first, period_range.last).sum(:amount)
    # Convert credits to euros (100 credits = 1€) and make revenue positive
    -payments / 100.0
  end

  private

  def weekly_refunds
    week_range = week_start..(week_start + 7.days)
    refunds_for_period(week_range)
  end

  def monthly_refunds
    month_range = month_start..month_start.end_of_month
    refunds_for_period(month_range)
  end

  def refunds_for_period(period_range)
    # Les remboursements sont en crédits, on les convertit en euros (100 crédits = 1€)
    refunds_cents = CreditTransaction.refunds.in_period(period_range.first, period_range.last).sum(:amount)
    refunds_cents / 100.0
  end
end
end
