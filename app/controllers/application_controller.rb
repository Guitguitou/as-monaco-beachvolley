class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  before_action :authenticate_user!, except: :accueil
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_non_activated_users

  def accueil
    # Redirect authenticated non-activated users to packs
    if user_signed_in? && Users::ActivationGate.restricted?(current_user)
      redirect_to packs_path
      return
    end

    @next_stage = Stage.ordered_for_players.find { |stage| stage.current_or_upcoming? }
    @members_count = User.count
    @terrains_count = Session.terrains.size
    @sessions_per_month = Session.in_current_month.count

    render layout: "home"
  end

  protected

  def after_sign_in_path_for(resource)
    # Redirect non-activated users to packs
    if Users::ActivationGate.restricted?(resource)
      packs_path
    else
      # « Mon terrain » : sa prochaine session et les sessions ouvertes pour lui.
      # On atterrissait auparavant sur les classements, qui ne disent pas au
      # joueur quand il joue.
      home_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  private

  # Ajoute des messages à l'alerte déjà en flash au lieu de l'écraser.
  def append_flash_alert(messages)
    flash[:alert] = [ flash[:alert], *messages ].compact_blank.join("; ") if messages.any?
  end

  # Redirect non-activated users to limited pages
  def redirect_non_activated_users
    return unless user_signed_in? && Users::ActivationGate.restricted?(current_user)
    return if Users::ActivationGate.allows?(request.path)

    redirect_to packs_path, alert: "Ton compte n'est pas encore activé. Prends une licence ou un pack stage pour accéder à tout."
  end
end
