# frozen_string_literal: true

module Users
  # Un membre pas encore activé (ni licence ni pack stage) n'accède qu'aux
  # pages qui lui permettent de s'en procurer un, et aux infos du club.
  # Admins et gestionnaires financiers ont toujours accès à tout.
  module ActivationGate
    OPEN_PREFIXES = [ "/stages/", "/checkout" ].freeze
    OPEN_PATTERN = %r{/packs/\d+/buy}
    OPEN_ROUTES = %i[
      packs_path stages_path profile_path destroy_user_session_path new_user_session_path user_session_path
      new_user_registration_path user_registration_path edit_user_registration_path
      infos_root_path infos_videos_path infos_planning_trainings_path infos_planning_season_path
      infos_internal_rules_path infos_reservations_leads_path infos_brochure_path infos_registration_rules_path
    ].freeze

    def self.restricted?(user)
      !user.activated? && !user.admin? && !user.financial_manager?
    end

    def self.allows?(path)
      open_paths.include?(path) || path.start_with?(*OPEN_PREFIXES) || path.match?(OPEN_PATTERN)
    end

    def self.open_paths
      routes = Rails.application.routes.url_helpers
      OPEN_ROUTES.map { |route| routes.public_send(route) }
    end
  end
end
