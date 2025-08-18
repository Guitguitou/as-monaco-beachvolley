class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:create, :destroy]

  def create
    authorize! :create, Registration
    requested_waitlist = ActiveModel::Type::Boolean.new.cast(params[:waitlist])
    registration = Registration.new(user: current_user, session: @session, status: requested_waitlist ? :waitlisted : :confirmed)

    begin
      ActiveRecord::Base.transaction do
        registration.save!
        amount = registration.required_credits_for(current_user)
        if amount.positive? && registration.confirmed?
          TransactionService.new(current_user, @session, amount).create_transaction
        end
      end
      redirect_to session_path(@session), notice: "Inscription réussie ✅"
    rescue StandardError => e
      error_message = registration.errors.full_messages.presence || [e.message]
      redirect_to session_path(@session), alert: error_message.to_sentence
    end
  end

  def destroy
    authorize! :destroy, Registration
    registration = current_user.registrations.find_by(session: @session)

    if registration
      amount = registration.required_credits_for(current_user)
      begin
        ActiveRecord::Base.transaction do
          registration.destroy!
          # Refund only if before deadline or if no deadline defined
          refundable = amount.positive? && (
            # Apply deadline rule only for trainings
            !@session.entrainement? ||
            @session.cancellation_deadline_at.blank? || Time.current <= @session.cancellation_deadline_at
          )
          if refundable
            TransactionService.new(
              current_user,
              @session,
              amount
            ).refund_transaction
          end
          # After freeing up a spot, promote the first in waitlist if any
          @session.promote_from_waitlist!
        end
        notice_msg = if amount.positive? && !refundable
                        "Désinscription réussie, mais délai dépassé — pas de remboursement."
                      else
                        "Désinscription réussie ✅"
                      end
        redirect_to session_path(params[:session_id]), notice: notice_msg
      rescue StandardError => e
        redirect_to session_path(params[:session_id]), alert: "Erreur lors de la désinscription: #{e.message}"
      end
    else
      redirect_to session_path(params[:session_id]), alert: "Tu n'es pas inscrit."
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end
end
