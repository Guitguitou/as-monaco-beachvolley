class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:create, :destroy]

  def create
    registration = Registration.new(user: current_user, session: @session)

    if registration.save
      TransactionService.new(
        current_user,
        @session,
        registration.session_price_for(current_user)
      ).create_transaction

      redirect_to session_path(@session), notice: "Inscription réussie ✅"
    else
      redirect_to session_path(@session), alert: registration.errors.full_messages.to_sentence
    end
  end

  def destroy
    registration = current_user.registrations.find_by(session: @session)

    if registration
      amount = registration.session_price_for(current_user)

      registration.destroy

      TransactionService.new(
        current_user,
        @session,
        amount
      ).refund_transaction

      redirect_to session_path(params[:session_id]), notice: "Désinscription réussie ✅"
    else
      redirect_to session_path(params[:session_id]), alert: "Tu n'es pas inscrit."
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end
end
