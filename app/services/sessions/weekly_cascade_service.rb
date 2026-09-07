module Sessions
  # Le rang de priorité hebdomadaire d'un joueur (cf. Registrations::WeeklyPriorityRule)
  # dépend de SES autres entraînements confirmés de la semaine. Quand l'un d'eux
  # disparaît — désinscription — ses autres inscriptions de la même semaine peuvent
  # redevenir prioritaires, mais rien ne les recalcule : leur session n'a pas bougé.
  # On rejoue donc le rééquilibrage sur ces sessions, une seule fois.
  #
  # Aucune récursion possible : ce service n'appelle que PriorityBalancerService,
  # jamais lui-même.
  class WeeklyCascadeService
    def self.call(user:, session:)
      new(user: user, session: session).call
    end

    def initialize(user:, session:)
      @user = user
      @session = session
    end

    def call
      return if user.blank? || !session.entrainement? || session.start_at.blank?
      return if Registrations::WeeklyPriorityRule.neutral_week?(session.start_at)

      peer_sessions.each { |peer| Sessions::PriorityBalancerService.call(session: peer) }
    end

    private

    attr_reader :user, :session

    def peer_sessions
      Session.trainings
             .where(start_at: Registrations::WeeklyPriorityRule.week_range(session.start_at))
             .where.not(id: session.id)
             .where(id: Registration.where(user_id: user.id).select(:session_id))
             .where("start_at >= ?", Time.current)
             .to_a
    end
  end
end
