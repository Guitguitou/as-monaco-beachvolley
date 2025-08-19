class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :session

  enum :status, { confirmed: 0, waitlisted: 1 }

  after_initialize do
    self.status ||= :confirmed if has_attribute?(:status)
  end

  validates :user_id, uniqueness: { scope: :session_id }

  validate :enough_credits?
  validate :can_register?
  validate :no_schedule_conflict

  def can_register?
    # Opening rules with 24h priority for competition license
    open_ok, open_reason = session.registration_open_state_for(user)
    unless open_ok
      errors.add(:base, open_reason)
    end

    if session.coaching_prive?
      errors.add(:base, "Les coachings privés ne sont pas ouverts à l’inscription.")
    end

    unless level_allowed?
      errors.add(:base, "Ce n’est pas ton niveau d'entrainement.")
    end

    # Only block on full if trying to confirm, not when waitlisting
    if confirmed? && session.full?
      errors.add(:base, "Session complète.")
    end

    if !enough_credits?
      errors.add(:base, "Pas assez de crédits.")
    end
  end

  def can_register_with_reason
    open_ok, open_reason = session.registration_open_state_for(user)
    return [false, open_reason] unless open_ok

    return [false, "Les coachings privés ne sont pas ouverts à l’inscription."] if session.coaching_prive?

    unless level_allowed?
      return [false, "Ce n’est pas ton niveau d'entrainement."]
    end

    # Only show full message for confirmed registrations
    return [false, "Session complète."] if confirmed? && session.full?

    # Schedule conflict only for confirmed
    if confirmed?
      overlap_exists = user
        .sessions_registered
        .where("start_at < ? AND end_at > ?", session.end_at, session.start_at)
        .where.not(id: session.id)
        .exists?
      return [false, "Tu es déjà inscrit à une autre session sur le même créneau."] if overlap_exists
    end

    if !enough_credits?
      return [false, "Tu n'as pas assez de crédits."]
    end

    [true, nil]
  end

  def enough_credits?
    user.balance.amount >= required_credits_for(user)
  end

  def required_credits_for(user)
    # Waitlisted users have not paid yet; do not require/refund credits
    return 0 if session.coaching_prive? || waitlisted?
    session.price.to_i
  end

  def level_allowed?
    # Only enforce levels for training sessions
    return true unless session.entrainement?

    # If the session accepts all levels (no level specified), allow anyone
    return true if session.levels.empty?

    # Otherwise, user must have a level matching the session
    return false if user.level.nil?
    session.levels.include?(user.level)
  end

  def no_schedule_conflict
    # Only applies to confirmed registrations; waitlisted users can queue
    return if waitlisted?

    # Overlap: existing.start < new_end AND existing.end > new_start
    overlap_exists = user
      .sessions_registered
      .where("start_at < ? AND end_at > ?", session.end_at, session.start_at)
      .where.not(id: session.id)
      .exists?

    if overlap_exists
      errors.add(:base, "Tu es déjà inscrit à une autre session sur le même créneau.")
    end
  end
end
