# frozen_string_literal: true

module Admin
  # Socle des pages d'administration : layout du dashboard et contrôle d'accès.
  # Chaque contrôleur choisit sa garde : admin seul, ou admin et gestionnaire
  # financier pour les pages de chiffres.
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!

    private

    def require_admin!
      deny_access unless current_user.admin?
    end

    def require_admin_or_financial_manager!
      deny_access unless current_user.admin? || current_user.financial_manager?
    end

    def deny_access
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
