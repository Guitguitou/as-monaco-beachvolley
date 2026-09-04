# frozen_string_literal: true

module Profile
  # Onglet « Mon encadrement » : coach, responsable, admin.
  #
  # Le responsable n'avait aucune page dédiée dans l'app, et l'espace coach
  # (/coach/trainings) n'était référencé par aucun menu — ni navbar, ni sidebar,
  # ni barre de navigation basse. Cet onglet est son point d'entrée.
  class Coaching
    SUPERVISED_LIMIT = 6
    ANNONCES_LIMIT = 5

    def initialize(user:)
      @user = user
    end

    def coach?
      user.coach? || user.admin?
    end

    def responsable?
      user.responsable? || user.admin?
    end

    # Revenus : seulement pour un coach dont la rémunération est renseignée.
    def earnings?
      coach? && user.salary_per_training_cents.to_i.positive?
    end

    def earnings
      return nil unless earnings?

      @earnings ||= salaries.periods_for_coach(
        user,
        week_range: week_range,
        month_range: month_range,
        year_range: year_range
      )
    end

    def monthly_history
      return [] unless earnings?

      @monthly_history ||= salaries.monthly_history_for_coach(user)
    end

    # Sessions dont l'utilisateur est le titulaire (coach ou responsable).
    def upcoming_supervised
      @upcoming_supervised ||= Session
        .where(user_id: user.id)
        .upcoming
        .ordered_by_start
        .includes(:levels, registrations: :user)
        .limit(SUPERVISED_LIMIT)
        .to_a
    end

    # Coach::TrainingsController est gardé par `ensure_coach_or_admin!` : ne pas
    # proposer le lien à un responsable, qui serait redirigé.
    def library_available?
      coach?
    end

    def my_annonces
      @my_annonces ||= Annonce
        .where(user_id: user.id)
        .ordered_by_recent
        .includes(:levels, :slots)
        .limit(ANNONCES_LIMIT)
        .to_a
    end

    def supervised_stages
      @supervised_stages ||= Stage
        .where(main_coach_id: user.id)
        .or(Stage.where(assistant_coach_id: user.id))
        .order(starts_on: :desc)
        .limit(SUPERVISED_LIMIT)
        .to_a
    end

    def confirmed_count(session)
      session.registrations.count(&:confirmed?)
    end

    private

    attr_reader :user

    def salaries
      @salaries ||= Reporting::CoachSalaries.new
    end

    def week_range
      Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
    end

    def month_range
      Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
    end

    def year_range
      Time.zone.now.beginning_of_year..Time.zone.now.end_of_year
    end
  end
end
