module Registrations
  EligibilityResult = Struct.new(:allowed?, :code, :reason, keyword_init: true)

  class EligibilityChecker
    def self.call(registration:)
      new(registration: registration).call
    end

    def initialize(registration:)
      @registration = registration
    end

    def call
      open_ok, open_reason = if registration.allow_deadline_bypass
        registration.session.registration_open_state_for(registration.user, skip_deadline: true)
      else
        registration.session.registration_open_state_for(registration.user)
      end
      return disallowed(:registration_closed, open_reason) unless open_ok

      if registration.session.coaching_prive? && !registration.allow_private_coaching_registration
        return disallowed(:private_coaching_closed, "Les coachings privés ne sont pas ouverts à l’inscription.")
      end

      return disallowed(:invalid_level, "Ce n’est pas ton niveau d'entrainement.") unless registration.level_allowed?
      return disallowed(:session_full, "Session complète.") if registration.confirmed? && registration.session.full?
      return disallowed(:insufficient_credits, "Pas assez de crédits.") unless registration.enough_credits?

      EligibilityResult.new(allowed?: true, code: nil, reason: nil)
    end

    private

    attr_reader :registration

    def disallowed(code, reason)
      EligibilityResult.new(allowed?: false, code: code, reason: reason)
    end
  end
end
