# frozen_string_literal: true

# Service pour charger les données relatives aux coaches
# Extrait la logique métier depuis Admin::UsersController et UsersController
class CoachDataService
  def initialize(user)
    @user = user
  end

  def training_counts
    {
      week: training_count_for_period(DateRangeService.week_range),
      month: training_count_for_period(DateRangeService.month_range),
      year: training_count_for_period(DateRangeService.year_range)
    }
  end

  def salaries
    counts = training_counts
    spt = @user.salary_per_training
    {
      week: (counts[:week] * spt).to_f,
      month: (counts[:month] * spt).to_f,
      year: (counts[:year] * spt).to_f
    }
  end

  def past_trainings(limit: 50)
    Session.includes(:levels, :registrations)
           .where(user_id: @user.id, session_type: 'entrainement')
           .where('start_at < ?', Time.current)
           .order(start_at: :desc)
           .limit(limit)
  end

  def upcoming_trainings(limit: 20)
    Session.includes(:levels, :registrations)
           .where(user_id: @user.id, session_type: 'entrainement')
           .where('start_at >= ?', Time.current)
           .order(start_at: :asc)
           .limit(limit)
  end

  def monthly_salary_data(months: 12)
    data = []
    months.times do |i|
      month_start = (Time.current - i.months).beginning_of_month
      month_end = month_start.end_of_month

      training_count = Session.where(
        user_id: @user.id,
        session_type: 'entrainement',
        start_at: month_start..month_end
      ).count

      total_salary = training_count * @user.salary_per_training

      data << {
        month_name: month_start.strftime('%B %Y'),
        training_count: training_count,
        total_salary: total_salary
      }
    end
    data.reverse # Show oldest to newest
  end

  private

  def training_count_for_period(range)
    Session.where(
      user_id: @user.id,
      session_type: 'entrainement',
      start_at: range
    ).count
  end
end

