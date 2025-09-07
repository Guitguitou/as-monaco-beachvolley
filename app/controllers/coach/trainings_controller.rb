# frozen_string_literal: true

module Coach
  class TrainingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_coach_or_admin!

    def index
      @active_tab = params[:tab] || 'library'
      
      case @active_tab
      when 'library'
        load_library_data
      when 'my_trainings'
        load_my_trainings_data
      end
    end

    private

    def load_library_data
      # Show trainings grouped by level with latest notes first
      trainings = Session.includes(:levels)
                         .where(session_type: 'entrainement')
                         .where.not(coach_notes: [nil, ''])
                         .order(start_at: :desc)

      # Optional filter: only sessions coached by me
      if params[:only_mine].present?
        trainings = trainings.where(user_id: current_user.id)
      end

      # Group by level id (sessions may have multiple levels; duplicate in multiple groups)
      @by_level_id = Hash.new { |h, k| h[k] = [] }
      trainings.each do |s|
        if s.levels.any?
          s.levels.each { |lvl| @by_level_id[lvl.id] << s }
        else
          @by_level_id[nil] << s
        end
      end

      @levels = Level.where(id: @by_level_id.keys.compact).index_by(&:id)
    end

    def load_my_trainings_data
      # Calculate coach revenues for different periods
      week_range  = Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
      month_range = Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
      year_range  = Time.zone.now.beginning_of_year..Time.zone.now.end_of_year

      # My training counts and revenues
      @my_trainings_week_count  = Session.where(user_id: current_user.id, session_type: 'entrainement', start_at: week_range).count
      @my_trainings_month_count = Session.where(user_id: current_user.id, session_type: 'entrainement', start_at: month_range).count
      @my_trainings_year_count  = Session.where(user_id: current_user.id, session_type: 'entrainement', start_at: year_range).count

      spt = current_user.salary_per_training
      @my_salary_week  = (@my_trainings_week_count  * spt).to_f
      @my_salary_month = (@my_trainings_month_count * spt).to_f
      @my_salary_year  = (@my_trainings_year_count  * spt).to_f

      # Past trainings with details
      @past_trainings = Session.includes(:levels, :registrations)
                              .where(user_id: current_user.id, session_type: 'entrainement')
                              .where('start_at < ?', Time.current)
                              .order(start_at: :desc)
                              .limit(50)

      # Upcoming trainings
      @upcoming_trainings = Session.includes(:levels, :registrations)
                                  .where(user_id: current_user.id, session_type: 'entrainement')
                                  .where('start_at >= ?', Time.current)
                                  .order(start_at: :asc)
                                  .limit(20)

      # Monthly salary data for the last 12 months
      @monthly_salary_data = []
      (0..11).each do |i|
        month_start = (Time.current - i.months).beginning_of_month
        month_end = month_start.end_of_month
        
        training_count = Session.where(
          user_id: current_user.id, 
          session_type: 'entrainement', 
          start_at: month_start..month_end
        ).count
        
        total_salary = training_count * current_user.salary_per_training
        
        @monthly_salary_data << {
          month_name: month_start.strftime("%B %Y"),
          training_count: training_count,
          total_salary: total_salary
        }
      end
      @monthly_salary_data.reverse! # Show oldest to newest
    end

    def ensure_coach_or_admin!
      redirect_to root_path, alert: "Accès réservé aux coachs/admins" unless current_user.admin? || current_user.coach?
    end
  end
end
