# frozen_string_literal: true

# Service pour gérer les inscriptions et désinscriptions aux sessions
# Extrait la logique métier depuis RegistrationsController
class RegistrationService
  def initialize(session, user, options = {})
    @session = session
    @user = user
    @options = options
  end

  def create(waitlist: false)
    check_registration_deadline! unless can_bypass_deadline?

    registration = Registration.new(
      user: @user,
      session: @session,
      status: waitlist ? :waitlisted : :confirmed
    )

    registration.allow_private_coaching_registration = true if can_register_private_coaching?
    registration.allow_deadline_bypass = true if can_bypass_deadline?

    ActiveRecord::Base.transaction do
      registration.save!
      amount = registration.required_credits_for(@user)
      if amount.positive? && registration.confirmed?
        TransactionService.new(@user, @session, amount).create_transaction
      end
    end

    { success: true, registration: registration }
  rescue StandardError => e
    error_message = registration&.errors&.full_messages&.presence || [e.message]
    { success: false, errors: error_message }
  end

  def destroy
    registration = find_registration
    return { success: false, errors: ["Tu n'es pas inscrit."] } unless registration

    check_session_ended! unless can_bypass_session_end?

    amount = registration.required_credits_for(@user)
    refundable = calculate_refundable(amount)

    ActiveRecord::Base.transaction do
      registration.destroy!
      if refundable
        TransactionService.new(@user, @session, amount).refund_transaction
      end
      log_late_cancellation(amount, refundable)
      @session.promote_from_waitlist!
    end

    notice_msg = build_notice_message(amount, refundable)
    { success: true, notice: notice_msg }
  rescue StandardError => e
    { success: false, errors: ["Erreur lors de la désinscription: #{e.message}"] }
  end

  private

  def find_registration
    if can_manage_others_registrations?
      @session.registrations.find_by(user_id: @user.id)
    else
      @user.registrations.find_by(session: @session)
    end
  end

  def check_registration_deadline!
    return unless @session.entrainement? && @session.past_registration_deadline?

    raise StandardError, "Les inscriptions sont closes (limite : 17h le jour de la session)."
  end

  def check_session_ended!
    return unless Time.current > @session.end_at

    raise StandardError, "La session est passée. Seul un administrateur peut retirer des joueurs."
  end

  def calculate_refundable(amount)
    return false unless amount.positive?

    # Apply deadline rule only for trainings
    return true unless @session.entrainement?

    @session.cancellation_deadline_at.blank? || Time.current <= @session.cancellation_deadline_at
  end

  def log_late_cancellation(amount, refundable)
    return unless amount.positive? && !refundable

    LateCancellation.create!(user: @user, session: @session)
  end

  def build_notice_message(amount, refundable)
    if amount.positive? && !refundable
      "Désinscription réussie, mais délai dépassé — pas de remboursement."
    else
      "Désinscription réussie ✅"
    end
  end

  def can_bypass_deadline?
    @options[:can_bypass_deadline] || false
  end

  def can_register_private_coaching?
    @options[:can_register_private_coaching] || false
  end

  def can_manage_others_registrations?
    @options[:can_manage_others_registrations] || false
  end

  def can_bypass_session_end?
    @options[:can_bypass_session_end] || false
  end
end

