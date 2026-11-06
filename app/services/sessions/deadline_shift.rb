# frozen_string_literal: true

module Sessions
  # Quand une session change d'heure, décale du même écart les deadlines que
  # l'admin n'a pas retouchées (ouverture des inscriptions, désinscription).
  # La deadline de 17h le jour J est dérivée de start_at et suit d'elle-même.
  module DeadlineShift
    DEADLINES = %i[cancellation_deadline_at registration_opens_at].freeze

    def self.apply(session, old_start)
      return unless session.start_at_changed? && old_start.present? && session.start_at.present?

      days, seconds = shift(old_start, session.start_at)
      DEADLINES.each do |deadline|
        next if session[deadline].blank? || session.attribute_changed?(deadline)

        session[deadline] = session[deadline] + days.days + seconds.seconds
      end
    end

    # Écart en jours calendaires plus le reste en secondes : un décalage d'un
    # jour garde l'heure locale de la deadline, même au changement d'heure.
    def self.shift(from, to)
      days = (to.to_date - from.to_date).to_i
      [ days, to.seconds_since_midnight - from.seconds_since_midnight ]
    end
    private_class_method :shift
  end
end
