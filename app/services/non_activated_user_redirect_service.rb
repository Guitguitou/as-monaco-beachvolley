# frozen_string_literal: true

# Service to determine if a non-activated user should be redirected
class NonActivatedUserRedirectService
  ALLOWED_PATHS = [
    ->(path) { path.start_with?("/stages/") },
    ->(path) { path.start_with?("/checkout") },
    ->(path) { path =~ /\/packs\/\d+\/buy/ }
  ].freeze

  def initialize(user, request_path)
    @user = user
    @request_path = request_path
  end

  def should_redirect?
    return false unless user_signed_in?
    return false if @user.activated?
    return false if admin_or_financial_manager?

    !allowed_path?
  end

  def redirect_message
    "Votre compte n'est pas encore activé. Achetez une licence ou un pack stage pour accéder à toutes les fonctionnalités."
  end

  private

  def user_signed_in?
    @user.present?
  end

  def admin_or_financial_manager?
    @user.admin? || @user.financial_manager?
  end

  def allowed_path?
    static_allowed_paths.include?(@request_path) || dynamic_allowed_path?
  end

  def static_allowed_paths
    [
      packs_path,
      stages_path,
      profile_path,
      destroy_user_session_path,
      new_user_session_path,
      user_session_path,
      new_user_registration_path,
      user_registration_path,
      edit_user_registration_path,
      infos_root_path,
      infos_videos_path,
      infos_planning_trainings_path,
      infos_planning_season_path,
      infos_internal_rules_path,
      infos_reservations_leads_path,
      infos_brochure_path,
      infos_registration_rules_path
    ]
  end

  def dynamic_allowed_path?
    ALLOWED_PATHS.any? { |matcher| matcher.call(@request_path) }
  end
end
