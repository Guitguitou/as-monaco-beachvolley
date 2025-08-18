# frozen_string_literal: true
module Admin
  class DashboardController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def index
      starting = Time.zone.today.beginning_of_week
      ending   = starting + 7.days

      @upcoming_trainings = Session
        .where(session_type: 'entrainement')
        .where(start_at: starting..ending)
        .order(:start_at)

      @upcoming_free_plays = Session
        .where(session_type: 'jeu_libre')
        .where("start_at >= ?", Time.current)
        .order(:start_at)

      @upcoming_private_coachings = Session
        .where(session_type: 'coaching_prive')
        .where("start_at >= ?", Time.current)
        .order(:start_at)

      # Revenue (credits) for current month from session payments
      month_range = Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
      payment_types = [
        CreditTransaction.transaction_types[:training_payment],
        CreditTransaction.transaction_types[:free_play_payment],
        CreditTransaction.transaction_types[:private_coaching_payment]
      ]
      monthly_sum = CreditTransaction
        .where(transaction_type: payment_types)
        .where(created_at: month_range)
        .sum(:amount)
      # amounts are negative for payments, make revenue positive
      @current_month_revenue = -monthly_sum

      # Coach salaries (expected) for periods
      @coach_salary_week = coach_salary_between(starting..ending)
      @coach_salary_month = coach_salary_between(Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)
      @coach_salary_year = coach_salary_between(Time.zone.now.beginning_of_year..Time.zone.now.end_of_year)

      @coach_breakdown = coach_salary_breakdown(
        week_range: starting..ending,
        month_range: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month,
        year_range: Time.zone.now.beginning_of_year..Time.zone.now.end_of_year
      )
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user.admin?
    end

    def coach_salary_between(range)
      # Count trainings in range grouped by coach, multiply by salary_per_training_cents
      trainings = Session.where(session_type: 'entrainement', start_at: range)
      by_coach_counts = trainings.group(:user_id).count
      users = User.where(id: by_coach_counts.keys).index_by(&:id)
      total_cents = by_coach_counts.sum do |user_id, count|
        (users[user_id]&.salary_per_training_cents || 0) * count
      end
      total_cents / 100
    end

    def coach_salary_breakdown(week_range:, month_range:, year_range:)
      trainings = Session.where(session_type: 'entrainement')
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
  end
end
