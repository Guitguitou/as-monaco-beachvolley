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
  end
end
