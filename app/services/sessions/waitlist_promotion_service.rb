module Sessions
  class WaitlistPromotionService
    # `weekly_priority` est fourni par PriorityBalancerService, qui a déjà chargé
    # les priorités hebdomadaires : on évite alors toute requête supplémentaire.
    def self.call(session:, weekly_priority: nil)
      new(session: session, weekly_priority: weekly_priority).call
    end

    def initialize(session:, weekly_priority: nil)
      @session = session
      @weekly_priority = weekly_priority
    end

    def call
      return unless session.max_players.present?
      return if session.registrations.confirmed.count >= session.max_players

      session.session_levels.load # évite un N+1 dans priority_rank
      candidates = session.registrations.waitlisted.includes(user: :levels).to_a
      weekly.prime(candidates)

      candidates
        .sort_by { |registration| sort_key(registration) }
        .each { |registration| return registration if promote_registration(registration) }

      nil
    end

    private

    attr_reader :session

    def sort_key(registration)
      [ weekly.rank_for(registration), registration.priority_rank,
        registration.created_at, registration.id ]
    end

    def weekly
      @weekly ||= @weekly_priority || Registrations::WeeklyPriorityResolver.new(session: session)
    end

    def promote_registration(registration)
      amount = session.coaching_prive? ? 0 : session.price.to_i

      if amount.positive? && registration.user.balance.amount < amount
        notifier.insufficient_credits(registration.user)
        return false
      end

      promote_with_transaction(registration, amount)
    end

    def promote_with_transaction(registration, amount)
      ActiveRecord::Base.transaction do
        registration.update!(status: :confirmed)
        TransactionService.new(registration.user, session, amount).create_transaction if amount.positive?
      end

      notifier.promoted(registration.user, cause: "Quelqu'un s'est désinscrit de la session")
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def notifier
      @notifier ||= WaitlistNotifier.new(session)
    end
  end
end
