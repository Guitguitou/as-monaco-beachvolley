# frozen_string_literal: true

module Sessions
  # Ce que le bouton d'inscription de la fiche session doit montrer au joueur.
  #
  # Un état par situation, chacun avec ce qui se passe au clic, ce que ça coûte
  # et, quand c'est bloqué, ce qui débloque : on ne montre jamais un bouton qui
  # ne mène nulle part.
  class CtaState
    KINDS = %i[registered waitlisted open waitlist not_yet_open no_credits wrong_level blocked].freeze

    attr_reader :session, :user, :registration

    def initialize(session:, user:, rules: ClubRules.current)
      @session = session
      @user = user
      @rules = rules
      @registration = Registration.find_by(session: session, user: user)
    end

    def kind
      @kind ||= compute_kind
    end

    def reason
      @reason ||= confirmed_check.last || waitlist_check.last
    end

    def cost
      session.coaching_prive? ? 0 : session.price.to_i
    end

    def balance
      @balance ||= user.balance&.amount.to_i
    end

    def balance_after
      balance - cost
    end

    def missing_credits
      [ cost - balance, 0 ].max
    end

    # Moment où le joueur pourra s'inscrire, pour un entraînement pas encore ouvert.
    def opens_at
      return unless session.entrainement? && session.registration_opens_at.present?
      return session.registration_opens_at if Time.current < session.registration_opens_at

      rules.priority_ends_at(session.registration_opens_at)
    end

    # Position estimée si le joueur rejoint (ou a rejoint) la liste d'attente.
    def waitlist_position
      if registration&.waitlisted?
        ids = Sessions::WaitlistOrder.call(session: session).map(&:user_id)
        (ids.index(user.id) || ids.size) + 1
      else
        session.registrations.waitlisted.count + 1
      end
    end

    def weekly_secondary?
      Registrations::UserWeeklyPriorityMap.call(user: user, sessions: [ session ])[session.id] ==
        Registrations::WeeklyPriorityRule::SECONDARY
    end

    # Le crédit est-il rendu si le joueur se désinscrit maintenant ?
    # Reprend les règles de Registrations::Cancellation.
    def refundable_now?
      return false unless registration&.confirmed? && cost.positive?
      return false if Time.current > session.start_at

      refund_deadline.nil? || Time.current <= refund_deadline
    end

    def refund_deadline
      session.cancellation_deadline_at if session.entrainement?
    end

    def can_unsubscribe?
      registration.present? && (Time.current <= session.end_at || user.admin?)
    end

    private

    attr_reader :rules

    def compute_kind
      return registration.waitlisted? ? :waitlisted : :registered if registration
      return :open if confirmed_check.first
      return :waitlist if session.full? && waitlist_check.first

      case eligibility_code
      when :insufficient_credits then :no_credits
      when :invalid_level then :wrong_level
      when :registration_closed then opens_at&.future? ? :not_yet_open : :blocked
      else :blocked
      end
    end

    def eligibility_code
      Registrations::EligibilityChecker.call(registration: Registration.new(user: user, session: session, status: :confirmed)).code
    end

    def confirmed_check
      @confirmed_check ||= Registration.new(user: user, session: session, status: :confirmed).can_register_with_reason
    end

    def waitlist_check
      @waitlist_check ||= Registration.new(user: user, session: session, status: :waitlisted).can_register_with_reason
    end
  end
end
