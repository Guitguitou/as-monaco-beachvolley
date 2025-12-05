# frozen_string_literal: true

# Service pour synchroniser les participants d'une session
# Extrait la logique métier de synchronisation des participants depuis les controllers
class SyncParticipantsService
  def initialize(session, participant_ids, options = {})
    @session = session
    @participant_ids = Array(participant_ids).reject(&:blank?).map(&:to_i)
    @options = options
  end

  def call
    current_ids = @session.participants.pluck(:id)
    ids_to_add = @participant_ids - current_ids
    ids_to_remove = current_ids - @participant_ids

    errors = []

    add_participants(ids_to_add, errors)
    remove_participants(ids_to_remove, errors)

    { success: errors.empty?, errors: errors }
  end

  private

  def add_participants(user_ids, errors)
    user_ids.each do |user_id|
      add_participant(user_id, errors)
    end
  end

  def add_participant(user_id, errors)
    user = User.find(user_id)
    registration = Registration.new(
      user: user,
      session: @session,
      status: :confirmed
    )

    # Allow privileged add for private coachings
    if @session.coaching_prive? && can_manage_registrations?
      registration.allow_private_coaching_registration = true
    end

    # Allow admin to bypass registration deadline
    if can_bypass_deadline?
      registration.allow_deadline_bypass = true
    end

    ActiveRecord::Base.transaction do
      registration.save!
      amount = registration.required_credits_for(user)
      if amount.positive?
        TransactionService.new(user, @session, amount).create_transaction
      end
    end
  rescue StandardError => e
    errors << "#{user.full_name}: #{registration.errors.full_messages.presence || e.message}"
  end

  def remove_participants(user_ids, errors)
    user_ids.each do |user_id|
      remove_participant(user_id, errors)
    end
  end

  def remove_participant(user_id, errors)
    registration = @session.registrations.find_by(user_id: user_id)
    return unless registration

    user = registration.user
    amount = registration.required_credits_for(user)

    ActiveRecord::Base.transaction do
      registration.destroy!
      if amount.positive?
        TransactionService.new(user, @session, amount).refund_transaction
      end
      @session.promote_from_waitlist!
    end
  rescue StandardError => e
    errors << "#{user.full_name}: #{e.message}"
  end

  def can_manage_registrations?
    @options[:can_manage_registrations] || false
  end

  def can_bypass_deadline?
    @options[:can_bypass_deadline] || false
  end
end

