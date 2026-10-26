class RegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [ :create, :destroy ]

  def create
    authorize! :create, Registration

    if actor.deadline_blocks?
      return respond_after_change("Les inscriptions sont closes (limite : 17h le jour de la session).", kind: :alert)
    end

    result = Registrations::Enrollment.new(
      user: actor.target_user, session: @session,
      waitlist: ActiveModel::Type::Boolean.new.cast(params[:waitlist]), privileged: actor.privileged?
    ).call
    respond_after_change(result.message, kind: result.success? ? :notice : :alert)
  end

  def destroy
    authorize! :destroy, Registration
    registration = actor.registration
    return respond_after_change("Tu n'es pas inscrit.", kind: :alert) unless registration

    if actor.session_over_for?
      return respond_after_change("La session est passée. Seul un administrateur peut retirer des joueurs.", kind: :alert)
    end

    message = Registrations::Cancellation.new(registration, excused: actor.excused?).call
    # Sur la fiche, le joueur qui vient de se désinscrire peut revenir sur sa
    # décision d'un clic (cf. sessions/_reregister).
    flash[:reregister] = @session.id unless actor.acting_for_someone? || card_request?
    respond_after_change(message)
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
    state = Sessions::SingleCardState.call(session: @session.reload, user: current_user)

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

  def actor
    @actor ||= Registrations::Actor.new(current_user: current_user, session: @session, params: params)
  end
end
