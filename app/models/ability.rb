# frozen_string_literal: true

# Classe principale Ability qui délègue aux classes spécialisées
# Suit le pattern Strategy pour séparer les permissions par type d'utilisateur
class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new
    delegate_to_specialized_ability
  end

  private

  attr_reader :user

  def delegate_to_specialized_ability
    ability_class = find_ability_class
    specialized_ability = ability_class.new(user)
    # Copy rules from specialized ability to this ability
    specialized_ability.rules.each do |rule|
      rules << rule
    end
  end

  def find_ability_class
    return Abilities::AdminAbility if user.admin?
    return Abilities::FinancialManagerAbility if user.financial_manager?
    return Abilities::CoachAbility if user.coach?
    return Abilities::ResponsableAbility if user.responsable?
    return Abilities::ActivatedUserAbility if user.activated?
    return Abilities::NonActivatedUserAbility if user.id.present?

    # Fallback pour utilisateur anonyme ou invalide
    Abilities::BaseAbility
  end
end
