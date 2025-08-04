class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :session

  validate :can_register?

  def can_register?
    if session.coaching_prive?
      errors.add(:base, "Les coachings privés ne sont pas ouverts à l’inscription.")
    end

    if session.entrainement? && !session.levels.include?(user.level)
      errors.add(:base, "Ce n’est pas ton niveau d'entrainement.")
    end

    if session.full?
      errors.add(:base, "Session complète.")
    end

    if user.balance.amount < session_price_for(user)
      errors.add(:base, "Pas assez de crédits.")
    end
  end

  def can_register_with_reason
    return [false, "Les coachings privés ne sont pas ouverts à l’inscription."] if session.coaching_prive?

    unless session.entrainement? && session.levels.include?(user.level)
      return [false, "Ce n’est pas ton niveau d'entrainement."]
    end

    return [false, "Session complète."] if session.full?

    if user.balance.amount < session_price_for(user)
      return [false, "Tu n'as pas assez de crédits."]
    end

    [true, nil]
  end

  TRAINING_PRICE = 350
  FREE_PLAY_PRICE = 300
  PRIVATE_COACHING_PRICE = 500

  def session_price_for(user)
    case session.session_type
    when "entrainement" then 350
    when "jeu_libre"    then 300
    when "coaching_prive"
      user == session.user ? 500 : 0
    else
      0
    end
  end
end
