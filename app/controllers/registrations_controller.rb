class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:create, :destroy]

  def create
    authorize! :create, Registration
    
    # Check if registration deadline has passed (only for regular users on trainings)
    if @session.entrainement? && @session.past_registration_deadline? && !can_bypass_deadline?
      redirect_to session_path(@session), alert: "Les inscriptions sont closes (limite : 17h le jour de la session)." and return
    end
    
    # Only admins or the session owner (coach/responsable assigned to the session)
    # can register someone else via user_id. Otherwise, register current_user.
    target_user = if params[:user_id].present? && (current_user.admin? || current_user == @session.user)
                    User.find(params[:user_id])
                  else
                    current_user
                  end
    requested_waitlist = ActiveModel::Type::Boolean.new.cast(params[:waitlist])
    registration = Registration.new(user: target_user, session: @session, status: requested_waitlist ? :waitlisted : :confirmed)
    # Allow admin or session owner to add participants to private coachings
    registration.allow_private_coaching_registration = true if @session.coaching_prive? && (current_user.admin? || current_user == @session.user)
    # Allow admin or session owner to bypass registration deadline (17h)
    registration.allow_deadline_bypass = true if can_bypass_deadline?

    begin
      ActiveRecord::Base.transaction do
        registration.save!
        amount = registration.required_credits_for(registration.user)
        if amount.positive? && registration.confirmed?
          TransactionService.new(registration.user, @session, amount).create_transaction
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
    # Only admins or the session owner (coach/responsable assigned to the session)
    # can remove someone else. Otherwise, users can remove themselves only.
    registration = if params[:user_id].present? && (current_user.admin? || current_user == @session.user)
                     @session.registrations.find_by(user_id: params[:user_id])
                   else
                     current_user.registrations.find_by(session: @session)
                   end

    if registration
      # Forbid self/unprivileged unregistration after the session has ended.
      # After the session, only admins can remove players to handle refunds manually.
      if Time.current > @session.end_at && !current_user.admin?
        redirect_to session_path(@session), alert: "La session est passée. Seul un administrateur peut retirer des joueurs." and return
      end

      amount = registration.required_credits_for(registration.user)
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
              registration.user,
              @session,
              amount
            ).refund_transaction
          end
          # Log late cancellation when past refund deadline
          if amount.positive? && !refundable
            LateCancellation.create!(user: registration.user, session: @session)
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

  # Admins and the session coach can bypass the registration deadline
  def can_bypass_deadline?
    current_user.admin? || current_user == @session.user
  end
end
