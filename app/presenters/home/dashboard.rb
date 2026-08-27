# frozen_string_literal: true

module Home
  # Données de l'écran « Mon terrain ».
  #
  # Répond à la seule question que se pose un joueur qui ouvre l'app : quand
  # est-ce que je joue, et où est-ce que je peux m'inscrire. L'écran d'accueil
  # renvoyait jusqu'ici sur les classements.
  class Dashboard
    RECOMMENDED_LIMIT = 3
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
      @recommended_sessions ||= begin
        candidates = Sessions::EligibleForUserLevelsQuery.call(
          relation: Session.upcoming.ordered_by_start.where.not(session_type: "coaching_prive"),
          level_ids: level_ids
        ).includes(:levels, :user, registrations: :user).limit(30).to_a

        candidates
          .reject { |session| registered_session_ids.include?(session.id) }
          .select { |session| open_for_registration?(session) }
          .reject { |session| full?(session) }
          .first(RECOMMENDED_LIMIT)
      end
    end

    # Annonce de jeu libre la plus proche que le joueur peut rejoindre.
    def next_annonce
      @next_annonce ||= Annonces::EligibleAnnoncesQuery.call(user: user).first
    end

    def card_state_for(session)
      Sessions::CardState.new(
        session: session,
        user: user,
        registration: nil,
        confirmed_count: confirmed_count(session),
        conflict: false,
        balance: balance,
        user_level_ids: level_ids
      )
    end

    private

    attr_reader :user

    def level_ids
      @level_ids ||= user.levels.map(&:id)
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

    def registered_session_ids
      @registered_session_ids ||= user.registrations.pluck(:session_id).to_set
    end

    def confirmed_count(session)
      session.registrations.count(&:confirmed?)
    end

    def full?(session)
      session.max_players.present? && confirmed_count(session) >= session.max_players.to_i
    end

    def open_for_registration?(session)
      open, = session.registration_open_state_for(user)
      open
    end
  end
end
