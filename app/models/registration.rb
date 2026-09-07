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

  validate :enough_credits?
  validate :can_register?
  validate :no_schedule_conflict

  scope :valid, -> { where(status: :confirmed) }

  def can_register?
    result = Registrations::EligibilityChecker.call(registration: self)
    return if result.allowed?

    case result.code
    when :invalid_level
      errors.add(:user, "n’a pas le bon niveau pour cet entraînement")
      errors.add(:base, result.reason)
    when :session_full
      errors.add(:status, "impossible: session complète")
      errors.add(:base, result.reason)
    when :insufficient_credits
      errors.add(:user, "n’a pas assez de crédits")
      errors.add(:base, result.reason)
    else
      errors.add(:base, result.reason)
    end
  end

  def can_register_with_reason
    result = Registrations::EligibilityChecker.call(registration: self)
    return [false, result.reason] unless result.allowed?

    if confirmed? && Registrations::ScheduleConflictQuery.call(user: user, session: session).exists?
      return [false, "Tu es déjà inscrit à une autre session sur le même créneau."]
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

  def level_allowed?
    # Only enforce levels for training sessions
    return true unless session.entrainement?

    # If the session accepts all levels (no level specified), allow anyone
    return true if session.levels.empty?

    # Otherwise, user must have at least one level matching the session
    user_level_ids = if user.respond_to?(:levels)
                       user.levels.pluck(:id)
    else
                       []
    end
    # Backward-compat: consider legacy single level if present
    if user_level_ids.empty? && user.respond_to?(:level_id)
      user_level_ids = [ user.level_id ].compact
    end

    return false if user_level_ids.empty?
    (user_level_ids & session.level_ids).any?
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
