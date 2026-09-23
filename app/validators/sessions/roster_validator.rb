# frozen_string_literal: true

module Sessions
  # Inscriptions saisies avec la session (formulaire imbriqué) : un joueur
  # une seule fois, et pas plus de confirmés que de places.
  class RosterValidator < ActiveModel::Validator
    def validate(session)
      registrations = session.registrations.reject(&:marked_for_destruction?)
      user_ids = registrations.map(&:user_id)
      session.errors.add(:registrations, "ne peut participer qu'une seule fois à une session") if user_ids.uniq.size != user_ids.size
      return unless session.max_players.present? && registrations.count(&:confirmed?) > session.max_players

      session.errors.add(:registrations, "le nombre de participants ne peut pas dépasser #{session.max_players}")
    end
  end
end
