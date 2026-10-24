module Sessions
  class RegistrationPolicy
    def initialize(session:, user:, skip_deadline: false, rules: ClubRules.current)
      @session = session
      @user = user
      @skip_deadline = skip_deadline
      @rules = rules
    end

    def open_state
      return [ false, "Session annulée." ] if session.cancelled?
      return [ false, "L'inscription à ce tournoi se fait sur BVS." ] if session.tournament_id.present?
      return [ true, nil ] unless session.entrainement?
      return [ true, nil ] if session.registration_opens_at.blank?

      now = Time.current
      if now < session.registration_opens_at
        return [ false, "Les inscriptions ouvrent le #{I18n.l(session.registration_opens_at, format: :long)}." ]
      end

      within_priority_window = now < rules.priority_ends_at(session.registration_opens_at)
      if within_priority_window && user&.license_type != "competition"
        return [ false, "Priorité licence compétition pendant #{rules.priority_window_hours}h après l'ouverture." ]
      end

      if !skip_deadline && past_deadline?
        return [ false, "Les inscriptions sont closes (limite : #{rules.registration_deadline_hour}h le jour de la session)." ]
      end

      [ true, nil ]
    end

    def past_deadline?
      return false if session.start_at.blank?

      Time.current >= rules.registration_deadline_for(session.start_at)
    end

    private

    attr_reader :session, :user, :skip_deadline, :rules
  end
end
