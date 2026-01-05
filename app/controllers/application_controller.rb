class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  before_action :authenticate_user!, except: :accueil
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_non_activated_users

  def accueil
    # Redirect authenticated non-activated users to packs
    if user_signed_in? && !current_user.activated? && !current_user.admin? && !current_user.financial_manager?
      redirect_to packs_path
      return
    end
    
    render layout: 'home'
  end

  protected

  def after_sign_in_path_for(resource)
    # Redirect non-activated users to packs
    if !resource.activated? && !resource.admin? && !resource.financial_manager?
      packs_path
    else
      performances_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  private

  # Redirect non-activated users to limited pages
  def redirect_non_activated_users
    return unless user_signed_in?
    return if current_user.activated?
    return if current_user.admin? || current_user.financial_manager? # Admins and financial managers always have full access
    
    # Allow access to specific paths for non-activated users
    allowed_paths = [
      packs_path,
      stages_path,
      profile_path,
      destroy_user_session_path,
      new_user_session_path,
      user_session_path,
      new_user_registration_path,
      user_registration_path,
      edit_user_registration_path
    ]
    
    # Allow access to all infos pages
    allowed_paths += [
      infos_root_path,
      infos_videos_path,
      infos_planning_trainings_path,
      infos_planning_season_path,
      infos_internal_rules_path,
      infos_reservations_leads_path,
      infos_brochure_path,
      infos_registration_rules_path
    ]
    
    # Allow access to individual stage pages
    return if request.path.start_with?('/stages/')
    
    # Allow access to checkout pages (for pack purchase)
    return if request.path.start_with?('/checkout')
    
    # Allow access to pack buy action
    return if request.path =~ /\/packs\/\d+\/buy/
    
    unless allowed_paths.include?(request.path)
      redirect_to packs_path, alert: "Votre compte n'est pas encore activé. Achetez une licence ou un pack stage pour accéder à toutes les fonctionnalités."
    end
  end
end
