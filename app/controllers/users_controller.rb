class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @balance = @user.balance
    @transactions = @user.credit_transactions.order(created_at: :desc)

    # Coach salary stats (own only)
    if @user.coach?
      week_range  = Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
      month_range = Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
      year_range  = Time.zone.now.beginning_of_year..Time.zone.now.end_of_year

      @my_trainings_week_count  = Session.where(user_id: @user.id, session_type: 'entrainement', start_at: week_range).count
      @my_trainings_month_count = Session.where(user_id: @user.id, session_type: 'entrainement', start_at: month_range).count
      @my_trainings_year_count  = Session.where(user_id: @user.id, session_type: 'entrainement', start_at: year_range).count

      spt = @user.salary_per_training
      @my_salary_week  = (@my_trainings_week_count  * spt).to_f
      @my_salary_month = (@my_trainings_month_count * spt).to_f
      @my_salary_year  = (@my_trainings_year_count  * spt).to_f
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end
end
