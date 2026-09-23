# frozen_string_literal: true

module Home
  # Données de l'écran « Mon terrain ».
  #
  # Répond à la seule question que se pose un joueur qui ouvre l'app : quand
  # est-ce que je joue, et où est-ce que je peux m'inscrire. L'écran d'accueil
  # renvoyait jusqu'ici sur les classements.
  class Dashboard
    AGENDA_LIMIT = 4
    SUPERVISED_LIMIT = 4

    def initialize(user:)
      @user = user
    end

    # Prochaine session à laquelle le joueur est inscrit (liste principale ou attente).
    def next_registration
      agenda.first
    end

    # Les suivantes, hors la prochaine.
    def other_registrations
      agenda.drop(1)
    end

    def registered?
      agenda.any?
    end

    def supervisor?
      user.coach? || user.responsable?
    end

    def supervised_sessions
      @supervised_sessions ||= Session
        .where(user_id: user.id)
        .where("start_at >= ?", Time.current)
        .order(start_at: :asc)
        .includes(:levels, :user, registrations: :user)
        .limit(SUPERVISED_LIMIT)
        .to_a
    end

    def balance
      @balance ||= user.balance&.amount.to_i
    end

    # Sessions ouvertes correspondant aux niveaux du joueur, où il n'est pas
    # déjà inscrit et où il reste de la place.
    def recommended_sessions
      recommendations.sessions
    end

    delegate :card_state_for, to: :recommendations

    # Annonce de jeu libre la plus proche que le joueur peut rejoindre.
    def next_annonce
      @next_annonce ||= Annonces::EligibleAnnoncesQuery.call(user: user).first
    end

    private

    attr_reader :user

    def recommendations
      @recommendations ||= Sessions::Recommendations.new(user: user)
    end

    def agenda
      @agenda ||= user.registrations
        .joins(:session)
        .where("sessions.start_at >= ?", Time.current)
        .order("sessions.start_at ASC")
        .includes(session: [ :levels, :user, { registrations: :user } ])
        .limit(AGENDA_LIMIT)
        .to_a
    end
  end
end
