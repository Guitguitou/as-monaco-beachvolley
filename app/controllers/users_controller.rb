class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @balance = @user.balance
    @transactions = @user.credit_transactions.order(created_at: :desc)
    @active_tab = params[:tab] || 'profile'

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

      # Load training data for coaches tab
      if @active_tab == 'trainings'
        load_coach_trainings_data
      end
    end
  end

  private

    def load_coach_trainings_data
      # Past trainings with details
      @past_trainings = Session.includes(:levels, :registrations)
                              .where(user_id: @user.id, session_type: 'entrainement')
                              .where('start_at < ?', Time.current)
                              .order(start_at: :desc)
                              .limit(50)

      # Upcoming trainings
      @upcoming_trainings = Session.includes(:levels, :registrations)
                                  .where(user_id: @user.id, session_type: 'entrainement')
                                  .where('start_at >= ?', Time.current)
                                  .order(start_at: :asc)
                                  .limit(20)

      # Monthly salary data for the last 12 months
      @monthly_salary_data = []
      (0..11).each do |i|
        month_start = (Time.current - i.months).beginning_of_month
        month_end = month_start.end_of_month
        
        training_count = Session.where(
          user_id: @user.id, 
          session_type: 'entrainement', 
          start_at: month_start..month_end
        ).count
        
        total_salary = training_count * @user.salary_per_training
        
        @monthly_salary_data << {
          month_name: month_start.strftime("%B %Y"),
          training_count: training_count,
          total_salary: total_salary
        }
      end
      @monthly_salary_data.reverse! # Show oldest to newest
    end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end
end
