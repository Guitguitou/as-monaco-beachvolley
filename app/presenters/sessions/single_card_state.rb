# frozen_string_literal: true

module Sessions
  # Calcule l'état d'une seule carte de session (rafraîchissement Turbo Stream),
  # hors grille : les requêtes N+1 sont ici sans importance.
  class SingleCardState
    def self.call(session:, user:) = new(session, user).call

    def initialize(session, user)
      @session = session
      @user = user
    end

    def call
      CardState.new(
        session: @session, user: @user, registration: registration,
        confirmed_count: @session.registrations.count(&:confirmed?),
        conflict: conflict?, balance: @user&.balance&.amount, weekly_rank: weekly_rank
      )
    end

    private

    def registration
      @user && @session.registrations.find { |r| r.user_id == @user.id }
    end

    def conflict?
      @user.present? && Registrations::ScheduleConflictQuery.call(user: @user, session: @session).exists?
    end

    def weekly_rank
      @user && Registrations::UserWeeklyPriorityMap.call(user: @user, sessions: [ @session ])[@session.id]
    end
  end
end
