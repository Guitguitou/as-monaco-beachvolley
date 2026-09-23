# frozen_string_literal: true

module Coach
  # Bilan des entraînements d'un coach : revenus par période, historique
  # mensuel, séances passées et à venir.
  #
  # Ce chargement existait en trois copies (Coach::TrainingsController,
  # l'ancien UsersController et Admin::UsersController) et alimentait deux
  # vues de 242 lignes quasi identiques — l'une pour le coach, l'autre pour
  # l'admin qui consulte sa fiche.
  class TrainingsReport
    PAST_LIMIT = 50
    UPCOMING_LIMIT = 20

    def initialize(coach:)
      @coach = coach
    end

    attr_reader :coach

    def salary_per_training
      coach.salary_per_training
    end

    def week_count
      periods[:week][:count]
    end

    def week_amount
      periods[:week][:amount]
    end

    def month_count
      periods[:month][:count]
    end

    def month_amount
      periods[:month][:amount]
    end

    def year_count
      periods[:year][:count]
    end

    def year_amount
      periods[:year][:amount]
    end

    def monthly_history
      @monthly_history ||= payroll.monthly_history
    end

    def past_trainings
      @past_trainings ||= trainings.where(start_at: ...Time.current)
                                   .order(start_at: :desc)
                                   .limit(PAST_LIMIT)
                                   .to_a
    end

    def upcoming_trainings
      @upcoming_trainings ||= trainings.where("start_at >= ?", Time.current)
                                       .order(start_at: :asc)
                                       .limit(UPCOMING_LIMIT)
                                       .to_a
    end

    private

    def trainings
      Session.trainings.where(user_id: coach.id).includes(:levels, :registrations)
    end

    def periods
      @periods ||= payroll.current_periods
    end

    def payroll
      @payroll ||= Reporting::CoachPayroll.new(coach)
    end
  end
end
