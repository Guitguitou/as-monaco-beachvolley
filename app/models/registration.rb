class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :session

  validate :enough_credits?
  validate :can_register?

  def can_register?
    if session.coaching_prive?
      errors.add(:base, "Les coachings privés ne sont pas ouverts à l’inscription.")
    end

    unless level_allowed?
      errors.add(:base, "Ce n’est pas ton niveau d'entrainement.")
    end

    if session.full?
      errors.add(:base, "Session complète.")
    end

    if !enough_credits?
      errors.add(:base, "Pas assez de crédits.")
    end
  end

  def can_register_with_reason
    return [false, "Les coachings privés ne sont pas ouverts à l’inscription."] if session.coaching_prive?

    unless level_allowed?
      return [false, "Ce n’est pas ton niveau d'entrainement."]
    end

    return [false, "Session complète."] if session.full?

    if !enough_credits?
      return [false, "Tu n'as pas assez de crédits."]
    end

    [true, nil]
  end

  def enough_credits?
    user.balance.amount >= required_credits_for(user)
  end

  def required_credits_for(user)
    return 0 if session.coaching_prive?
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
end
