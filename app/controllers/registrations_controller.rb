class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [ :create, :destroy ]

  def create
    authorize! :create, Registration

    # Check if registration deadline has passed (only for regular users on trainings)
    if @session.entrainement? && @session.past_registration_deadline? && !can_bypass_deadline?
      respond_after_change("Les inscriptions sont closes (limite : 17h le jour de la session).", kind: :alert)
      return
    end

    target_user = acting_for_someone? ? User.find(params[:user_id]) : current_user
    result = Registrations::Enrollment.new(
      user: target_user, session: @session,
      waitlist: ActiveModel::Type::Boolean.new.cast(params[:waitlist]), privileged: can_bypass_deadline?
    ).call
    respond_after_change(result.message, kind: result.success? ? :notice : :alert)
  end

  def destroy
    authorize! :destroy, Registration
    registration = if acting_for_someone?
                     @session.registrations.find_by(user_id: params[:user_id])
    else
                     current_user.registrations.find_by(session: @session)
    end
    return respond_after_change("Tu n'es pas inscrit.", kind: :alert) unless registration

    # Après la session, seul un admin peut retirer un joueur (remboursement manuel).
    if Time.current > @session.end_at && !current_user.admin?
      return respond_after_change("La session est passée. Seul un administrateur peut retirer des joueurs.", kind: :alert)
    end

    respond_after_change(Registrations::Cancellation.new(registration).call)
  rescue StandardError => e
    respond_after_change("Erreur lors de la désinscription: #{e.message}", kind: :alert)
  end

  private

  # Une action lancée depuis une carte de la grille répond en Turbo Stream :
  # seule la carte et la zone de flash sont remplacées, la page ne bouge pas.
  # Ailleurs (fiche session, ajout par un admin), on garde la redirection.
  def card_request?
    params[:from] == "card" && request.format.turbo_stream?
  end

  def respond_after_change(message, kind: :notice)
    unless card_request?
      redirect_to session_path(@session, session_show_redirect_params), flash: { kind => message }
      return
    end

    flash.now[kind] = message
    state = Sessions::CardState.build(session: @session.reload, user: current_user)

    render turbo_stream: [
      turbo_stream.replace(
        "session_card_#{@session.id}",
        SessionCardComponent.new(state: state, return_params: session_show_redirect_params)
      ),
      turbo_stream.replace(FlashComponent::DOM_ID, FlashComponent.new(flash: flash))
    ]
  end

  def session_show_redirect_params
    Sessions::ReturnParams.from(params)
  end

  def set_session
    @session = Session.find(params[:session_id])
  end

  # Seuls un admin ou le coach de la session agissent pour un autre joueur.
  def acting_for_someone?
    params[:user_id].present? && can_bypass_deadline?
  end

  # Admins and the session coach can bypass the registration deadline
  def can_bypass_deadline?
    current_user.admin? || current_user == @session.user
  end
end
