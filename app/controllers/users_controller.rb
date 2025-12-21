# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @balance = @user.balance
    @transactions = @user.credit_transactions.order(created_at: :desc)
    @active_tab = params[:tab] || "profile"

    # Coach salary stats (own only)
    if @user.coach?
      coach_data = CoachDataService.new(@user)
      counts = coach_data.training_counts
      salaries = coach_data.salaries

      @my_trainings_week_count = counts[:week]
      @my_trainings_month_count = counts[:month]
      @my_trainings_year_count = counts[:year]
      @my_salary_week = salaries[:week]
      @my_salary_month = salaries[:month]
      @my_salary_year = salaries[:year]

      # Load training data for coaches tab
      if @active_tab == "trainings"
        load_coach_trainings_data
      end
    end
  end

  private

    def load_coach_trainings_data
      coach_data = CoachDataService.new(@user)
      @past_trainings = coach_data.past_trainings
      @upcoming_trainings = coach_data.upcoming_trainings
      @monthly_salary_data = coach_data.monthly_salary_data
    end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end
end
