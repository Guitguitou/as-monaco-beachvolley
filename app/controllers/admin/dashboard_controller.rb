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
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user.admin?
    end
  end
end
