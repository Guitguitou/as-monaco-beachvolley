# frozen_string_literal: true

module Sessions
  # Sessions à proposer à un joueur : ouvertes à ses niveaux, pas encore
  # rejointes, avec de la place, hors coachings privés.
  class Recommendations
    LIMIT = 3
    CANDIDATES = 30

    def initialize(user:)
      @user = user
      @level_ids = user.levels.map(&:id)
    end

    def sessions
      @sessions ||= candidates
        .reject { |session| joined_ids.include?(session.id) || full?(session) }
        .select { |session| session.registration_open_state_for(@user).first }
        .first(LIMIT)
    end

    def card_state_for(session)
      CardState.new(
        session: session, user: @user, registration: nil, confirmed_count: confirmed_count(session),
        conflict: false, balance: balance, user_level_ids: @level_ids, weekly_rank: weekly_ranks[session.id]
      )
    end

    private

    def candidates
      EligibleForUserLevelsQuery.call(
        relation: Session.upcoming.ordered_by_start.where.not(session_type: "coaching_prive"),
        level_ids: @level_ids
      ).includes(:levels, :user, registrations: :user).limit(CANDIDATES).to_a
    end

    def joined_ids
      @joined_ids ||= @user.registrations.pluck(:session_id).to_set
    end

    def balance
      @balance ||= @user.balance&.amount.to_i
    end

    # Une seule requête pour toutes les cartes proposées.
    def weekly_ranks
      @weekly_ranks ||= Registrations::UserWeeklyPriorityMap.call(user: @user, sessions: sessions)
    end

    def confirmed_count(session)
      session.registrations.count(&:confirmed?)
    end

    def full?(session)
      session.max_players.present? && confirmed_count(session) >= session.max_players.to_i
    end
  end
end
