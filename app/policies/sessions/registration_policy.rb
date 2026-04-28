module Sessions
  class RegistrationPolicy
    def initialize(session:, user:, skip_deadline: false)
      @session = session
      @user = user
      @skip_deadline = skip_deadline
    end

    def open_state
      return [true, nil] unless session.entrainement?
      return [true, nil] if session.registration_opens_at.blank?

      now = Time.current
      if now < session.registration_opens_at
        return [false, "Les inscriptions ouvrent le #{I18n.l(session.registration_opens_at, format: :long)}."]
      end

      within_priority_window = now < (session.registration_opens_at + Session::PRIORITY_WINDOW_HOURS.hours)
      if within_priority_window && user&.license_type != "competition"
        return [false, "Priorité licence compétition pendant 24h après l'ouverture."]
      end

      if !skip_deadline && past_deadline?
        return [false, "Les inscriptions sont closes (limite : 17h le jour de la session)."]
      end

      [true, nil]
    end

    def past_deadline?
      return false if session.start_at.blank?

      deadline = session.start_at.change(hour: Session::REGISTRATION_DEADLINE_HOUR, min: 0, sec: 0)
      Time.current >= deadline
    end

    private

    attr_reader :session, :user, :skip_deadline
  end
end
