class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :session

  enum :status, { confirmed: 0, waitlisted: 1 }

  # When true, allows creating registrations for private coachings
  # even though public registrations are closed for that session type.
  attr_accessor :allow_private_coaching_registration

  # When true, allows creating registrations after the registration deadline (17h)
  # for admins and session coaches.
  attr_accessor :allow_deadline_bypass

  after_initialize do
    self.status ||= :confirmed if has_attribute?(:status)
  end

  validates :user_id, uniqueness: { scope: :session_id }

  validate :can_register?
  validate :no_schedule_conflict

  scope :valid, -> { where(status: :confirmed) }

  # Refus d'éligibilité rattachés à un champ précis, en plus du message global.
  REFUSAL_ERRORS = {
    invalid_level: [ :user, "n’a pas le bon niveau pour cet entraînement" ],
    session_full: [ :status, "impossible: session complète" ],
    insufficient_credits: [ :user, "n’a pas assez de crédits" ]
  }.freeze

  def can_register?
    result = Registrations::EligibilityChecker.call(registration: self)
    return if result.allowed?

    attribute, message = REFUSAL_ERRORS[result.code]
    errors.add(attribute, message) if attribute
    errors.add(:base, result.reason)
  end

  def can_register_with_reason
    result = Registrations::EligibilityChecker.call(registration: self)
    return [ false, result.reason ] unless result.allowed?

    if confirmed? && Registrations::ScheduleConflictQuery.call(user: user, session: session).exists?
      return [ false, "Tu es déjà inscrit à une autre session sur le même créneau." ]
    end

    [ true, nil ]
  end

  def enough_credits?
    user.balance.amount >= required_credits_for(user)
  end

  def required_credits_for(user)
    # Waitlisted users have not paid yet; do not require/refund credits
    return 0 if session.coaching_prive? || waitlisted?
    session.price.to_i
  end

  # Rang de priorité du joueur pour cette session (plus petit = plus prioritaire).
  # = plus petit `priority` parmi les groupes de la session que possède le joueur.
  # Utilisé pour ordonner la liste principale des entraînements.
  def priority_rank
    return 0 unless session.entrainement?

    user_level_ids = user.level_ids
    matching = session.session_levels.select { |sl| user_level_ids.include?(sl.level_id) }
    matching.map(&:priority).min || Float::INFINITY
  end

  # Un entraînement réservé à des niveaux n'accepte que les joueurs qui en ont un.
  def level_allowed?
    return true unless session.entrainement? && session.levels.any?

    (user.levels.pluck(:id) & session.level_ids).any?
  end

  def no_schedule_conflict
    # Only applies to confirmed registrations; waitlisted users can queue
    return if waitlisted?

    # Overlap: existing.start < new_end AND existing.end > new_start
    overlap_exists = Registrations::ScheduleConflictQuery.call(user: user, session: session).exists?

    if overlap_exists
      errors.add(:session, "chevauche une autre session à laquelle tu es inscrit")
      errors.add(:base, "Tu es déjà inscrit à une autre session sur le même créneau.")
    end
  end
end
