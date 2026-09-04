# frozen_string_literal: true

module Reporting
  class CoachSalaries
    def initialize
      @current_time = Time.current
    end

    # Total des salaires pour une période
    def total_for_period(range)
      Reporting::CacheService.fetch("coach_salaries", "total_for_period", range.first.to_date, range.last.to_date) do
        sessions = Session.trainings.where(start_at: range)
        by_coach_counts = sessions.group(:user_id).count

        return 0 if by_coach_counts.empty?

        users = User.where(id: by_coach_counts.keys).index_by(&:id)
        total_cents = by_coach_counts.sum do |user_id, count|
          (users[user_id]&.salary_per_training_cents || 0) * count
        end

        total_cents / 100.0
      end
    end

    # Breakdown détaillé par coach pour plusieurs périodes
    def breakdown(week_range:, month_range:, year_range:)
      week_counts = Session.trainings.where(start_at: week_range).group(:user_id).count
      month_counts = Session.trainings.where(start_at: month_range).group(:user_id).count
      year_counts = Session.trainings.where(start_at: year_range).group(:user_id).count

      user_ids = (week_counts.keys + month_counts.keys + year_counts.keys).uniq
      users = User.where(id: user_ids).index_by(&:id)

      breakdown = user_ids.map do |user_id|
        user = users[user_id]
        salary_per_training = user&.salary_per_training_cents.to_i

        {
          user: user,
          week_count: week_counts[user_id].to_i,
          week_amount: (salary_per_training * week_counts[user_id].to_i) / 100.0,
          month_count: month_counts[user_id].to_i,
          month_amount: (salary_per_training * month_counts[user_id].to_i) / 100.0,
          year_count: year_counts[user_id].to_i,
          year_amount: (salary_per_training * year_counts[user_id].to_i) / 100.0,
          salary_per_training: salary_per_training / 100.0
        }
      end

      breakdown.sort_by { |h| -h[:month_amount] }
    end

    # Salaires par coach pour une période spécifique
    def by_coach_for_period(range)
      sessions = Session.trainings.where(start_at: range)
      by_coach_counts = sessions.group(:user_id).count

      return [] if by_coach_counts.empty?

      users = User.where(id: by_coach_counts.keys).index_by(&:id)

      by_coach_counts.map do |user_id, count|
        user = users[user_id]
        salary_per_training = user&.salary_per_training_cents.to_i
        total_amount = (salary_per_training * count) / 100.0

        {
          user: user,
          session_count: count,
          total_amount: total_amount,
          salary_per_training: salary_per_training / 100.0
        }
      end.sort_by { |h| -h[:total_amount] }
    end

    # Compteurs et montants d'un seul coach sur les trois périodes usuelles.
    #
    # Ce calcul était recopié à l'identique dans UsersController#show,
    # Coach::TrainingsController et Admin::UsersController.
    def periods_for_coach(coach, week_range:, month_range:, year_range:)
      salary_cents = coach.salary_per_training_cents.to_i

      counts = {
        week: Session.trainings.where(user_id: coach.id, start_at: week_range).count,
        month: Session.trainings.where(user_id: coach.id, start_at: month_range).count,
        year: Session.trainings.where(user_id: coach.id, start_at: year_range).count
      }

      counts.transform_values { |count| { count: count, amount: (salary_cents * count) / 100.0 } }
           .merge(salary_per_training: salary_cents / 100.0)
    end

    # Historique mensuel d'un coach, du plus ancien au plus récent.
    #
    # Une seule requête groupée, là où les trois copies faisaient un COUNT par
    # mois (12 requêtes).
    def monthly_history_for_coach(coach, months: 12)
      salary_cents = coach.salary_per_training_cents.to_i
      first_month = (@current_time - (months - 1).months).beginning_of_month
      last_month = @current_time.end_of_month

      counts_by_month = Session.trainings
                               .where(user_id: coach.id, start_at: first_month..last_month)
                               .group(Arel.sql("DATE_TRUNC('month', start_at)"))
                               .count
                               .transform_keys { |time| time.to_date.beginning_of_month }

      (0...months).map do |offset|
        month_start = (first_month + offset.months).to_date
        count = counts_by_month[month_start].to_i

        {
          month_name: I18n.l(month_start, format: :month_and_year),
          training_count: count,
          total_salary: (salary_cents * count) / 100.0
        }
      end
    end

    # Prochaines sessions pour un coach
    def upcoming_sessions_for_coach(coach, limit: 5)
      Session.trainings
             .where(user: coach)
             .upcoming
             .includes(:registrations, :levels)
             .ordered_by_start
             .limit(limit)
    end

    # Heures totales pour un coach sur une période
    def total_hours_for_coach(coach, range)
      sessions = Session.trainings
                       .where(user: coach, start_at: range)

      sessions.sum do |session|
        (session.end_at - session.start_at) / 1.hour
      end.round(1)
    end
  end
end
