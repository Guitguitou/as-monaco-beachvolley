# frozen_string_literal: true

module Sessions
  # Quand une session change d'heure, décale du même écart les deadlines que
  # l'admin n'a pas retouchées (ouverture des inscriptions, désinscription).
  # La deadline de 17h le jour J est dérivée de start_at et suit d'elle-même.
  module DeadlineShift
    DEADLINES = %i[cancellation_deadline_at registration_opens_at].freeze

    def self.apply(session, old_start)
      return unless session.start_at_changed? && old_start.present? && session.start_at.present?

      delta = session.start_at - old_start
      DEADLINES.each do |deadline|
        next if session[deadline].blank? || session.attribute_changed?(deadline)

        session[deadline] += delta
      end
    end
  end
end
