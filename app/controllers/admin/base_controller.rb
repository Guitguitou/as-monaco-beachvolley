# frozen_string_literal: true

module Admin
  # Socle de l'espace d'administration : layout commun et contrôle d'accès.
  # Réservé aux admins par défaut ; un contrôleur ouvert à d'autres profils
  # surcharge `authorized_user?`. Les droits fins restent dans Ability.
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :require_authorized_user!

    private

    def require_authorized_user!
      redirect_to root_path, alert: "Accès interdit" unless authorized_user?
    end

    def authorized_user?
      current_user.admin?
    end
  end
end
