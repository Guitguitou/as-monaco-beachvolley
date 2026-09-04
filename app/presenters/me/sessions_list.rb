# frozen_string_literal: true

module Me
  # Mes sessions, à venir et passées.
  #
  # Part des `Registration` et non de `user.sessions_registered` : cette
  # association passe par `confirmed_registrations`, donc les inscriptions en
  # liste d'attente étaient purement invisibles pour le joueur — il ne pouvait
  # pas savoir qu'il attendait une place.
  class SessionsList
    UPCOMING = "upcoming"
    PAST = "past"

    def initialize(user:, filter: nil)
      @user = user
      @filter = filter.to_s
    end

    def active_filter
      @active_filter ||= @filter == PAST ? PAST : UPCOMING
    end

    def upcoming?
      active_filter == UPCOMING
    end

    def registrations
      upcoming? ? upcoming_registrations : past_registrations
    end

    def upcoming_count
      @upcoming_count ||= upcoming_registrations.size
    end

    def past_count
      @past_count ||= past_registrations.size
    end

    def waitlisted_count
      @waitlisted_count ||= upcoming_registrations.count(&:waitlisted?)
    end

    # Le conflit d'horaire n'a pas de sens ici : le joueur est déjà inscrit.
    def card_state_for(registration)
      session = registration.session

      Sessions::CardState.new(
        session: session,
        user: user,
        registration: registration,
        confirmed_count: session.registrations.count(&:confirmed?),
        conflict: false,
        balance: balance,
        user_level_ids: level_ids
      )
    end

    private

    attr_reader :user

    def upcoming_registrations
      @upcoming_registrations ||= scope
        .where("sessions.start_at >= ?", Time.current)
        .order("sessions.start_at ASC")
        .to_a
    end

    def past_registrations
      @past_registrations ||= scope
        .where("sessions.end_at < ?", Time.current)
        .order("sessions.start_at DESC")
        .to_a
    end

    def scope
      Registration
        .where(user_id: user.id)
        .joins(:session)
        .includes(session: [ :levels, :user, { registrations: :user } ])
    end

    def balance
      @balance ||= user.balance&.amount.to_i
    end

    def level_ids
      @level_ids ||= user.levels.map(&:id)
    end
  end
end
