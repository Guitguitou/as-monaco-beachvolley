# frozen_string_literal: true

# Service pour annuler une session et gérer les remboursements
# Extrait la logique métier depuis SessionsController#cancel
class SessionCancellationService
  def initialize(session)
    @session = session
  end

  def call
    ActiveRecord::Base.transaction do
      refund_all_participants
      refund_coach_for_private_coaching
      detach_transactions
      @session.destroy!
    end

    { success: true }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def refund_all_participants
    @session.registrations.includes(:user).find_each do |registration|
      amount = registration.required_credits_for(registration.user)
      if amount.positive?
        TransactionService.new(registration.user, @session, amount).refund_transaction
      end
      registration.destroy!
    end
  end

  def refund_coach_for_private_coaching
    return unless @session.coaching_prive?

    coach_amount = @session.send(:default_price)
    return unless coach_amount.positive?

    TransactionService.new(@session.user, @session, coach_amount).refund_transaction
  end

  def detach_transactions
    # Detach transactions from this session to avoid FK issues
    CreditTransaction.where(session_id: @session.id).update_all(session_id: nil)
  end
end

