class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :session

  enum :status, { confirmed: 0, waitlisted: 1 }

  # When true, allows creating registrations for private coachings
  # even though public registrations are closed for that session type.
  attr_accessor :allow_private_coaching_registration

  after_initialize do
    self.status ||= :confirmed if has_attribute?(:status)
  end

  validates :user_id, uniqueness: { scope: :session_id }

  validate :enough_credits?
  validate :can_register?
  validate :no_schedule_conflict
  validate :weekly_training_limit

  def can_register?
    # Opening rules with 24h priority for competition license
    open_ok, open_reason = session.registration_open_state_for(user)
    unless open_ok
      errors.add(:base, open_reason)
    end

    if session.coaching_prive? && !allow_private_coaching_registration
      errors.add(:base, "Les coachings privés ne sont pas ouverts à l’inscription.")
    end

    unless level_allowed?
      errors.add(:user, "n’a pas le bon niveau pour cet entraînement")
      errors.add(:base, "Ce n’est pas ton niveau d'entrainement.")
    end

    # Only block on full if trying to confirm, not when waitlisting
    if confirmed? && session.full?
      errors.add(:status, "impossible: session complète")
      errors.add(:base, "Session complète.")
    end

    if !enough_credits?
      errors.add(:user, "n’a pas assez de crédits")
      errors.add(:base, "Pas assez de crédits.")
    end
  end

  def can_register_with_reason
    open_ok, open_reason = session.registration_open_state_for(user)
    return [false, open_reason] unless open_ok

    return [false, "Les coachings privés ne sont pas ouverts à l’inscription."] if session.coaching_prive? && !allow_private_coaching_registration

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

    # Otherwise, user must have at least one level matching the session
    user_level_ids = if user.respond_to?(:levels)
                       user.levels.pluck(:id)
                     else
                       []
                     end
    # Backward-compat: consider legacy single level if present
    if user_level_ids.empty? && user.respond_to?(:level_id)
      user_level_ids = [user.level_id].compact
    end

    return false if user_level_ids.empty?
    (user_level_ids & session.level_ids).any?
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
      errors.add(:session, "chevauche une autre session à laquelle tu es inscrit")
      errors.add(:base, "Tu es déjà inscrit à une autre session sur le même créneau.")
    end
  end

  # Enforce: at most one training (entrainement) per week, except for the current week
  def weekly_training_limit
    # Only applies to confirmed registrations for training sessions
    return if waitlisted?
    return unless confirmed?
    return unless session&.entrainement?

    # Allow multiple registrations in the current week
    begin
      today_week_start = Time.zone.today.beginning_of_week(:monday)
      session_week_start = session.start_at.in_time_zone.beginning_of_week(:monday).to_date
      if session_week_start == today_week_start
        return
      end
    rescue StandardError
      # If time computations fail, default to enforcing the rule
    end

    week_start = session.start_at.in_time_zone.beginning_of_week(:monday)
    week_end = session.start_at.in_time_zone.end_of_week(:monday)

    already_registered_this_week = user
      .sessions_registered
      .where(session_type: 'entrainement')
      .where(start_at: week_start..week_end)
      .where.not(id: session.id)
      .exists?

    if already_registered_this_week
      errors.add(:base, "Tu as déjà un entraînement sur cette semaine. Une seule inscription est autorisée (hors semaine en cours).")
    end
  end
end
