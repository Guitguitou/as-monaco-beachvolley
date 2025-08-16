class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:create, :destroy]

  def create
    authorize! :create, Registration
    registration = Registration.new(user: current_user, session: @session)

    begin
      ActiveRecord::Base.transaction do
        registration.save!
        amount = registration.required_credits_for(current_user)
        if amount.positive?
          TransactionService.new(
            current_user,
            @session,
            amount
          ).create_transaction
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
          if amount.positive?
            TransactionService.new(
              current_user,
              @session,
              amount
            ).refund_transaction
          end
        end
        redirect_to session_path(params[:session_id]), notice: "Désinscription réussie ✅"
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
