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
    # Create a temporary instance to get the abilities definition
    # Then apply those abilities in this context
    temp_ability = ability_class.new(user)
    # Copy rules by re-applying them in this context
    temp_ability.rules.each do |rule|
      apply_rule(rule)
    end
  end

  def apply_rule(rule)
    # Re-apply the rule in this ability's context
    if rule.block
      can rule.actions, rule.subjects, &rule.block
    elsif rule.conditions.is_a?(Hash) && !rule.conditions.empty?
      # Hash conditions like { id: user.id }
      can rule.actions, rule.subjects, rule.conditions
    elsif rule.conditions.empty?
      # No conditions
      can rule.actions, rule.subjects
    else
      # Other condition types - try to apply as hash
      can rule.actions, rule.subjects, rule.conditions if rule.conditions.is_a?(Hash)
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
