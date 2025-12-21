# frozen_string_literal: true

# Main Ability class that delegates to specialized ability classes.
# Uses Strategy pattern to separate permissions by user type.
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
    temp_ability = ability_class.new(user)
    temp_ability.rules.each do |rule|
      apply_rule(rule)
    end
  end

  def apply_rule(rule)
    return apply_rule_with_block(rule) if rule.block
    return apply_rule_with_conditions(rule) if rule.conditions.is_a?(Hash) && !rule.conditions.empty?
    return apply_rule_simple(rule) if rule.conditions.empty?

    apply_rule_with_conditions(rule) if rule.conditions.is_a?(Hash)
  end

  def apply_rule_with_block(rule)
    can rule.actions, rule.subjects, &rule.block
  end

  def apply_rule_with_conditions(rule)
    can rule.actions, rule.subjects, rule.conditions
  end

  def apply_rule_simple(rule)
    can rule.actions, rule.subjects
  end

  def find_ability_class
    return Abilities::AdminAbility if user.admin?
    return Abilities::FinancialManagerAbility if user.financial_manager?
    return Abilities::CoachAbility if user.coach?
    return Abilities::ResponsableAbility if user.responsable?
    return Abilities::ActivatedUserAbility if user.activated?
    return Abilities::NonActivatedUserAbility if user.id.present?

    Abilities::BaseAbility
  end
end
