# frozen_string_literal: true

module Admin
  class SeasonController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def show
      @activated_count = User.activated.count
      @renewed_count = User.activated.renewed_for_next_season.count
      @to_deactivate_count = @activated_count - @renewed_count
    end

    def reset
      result = Licenses::ResetSeason.call

      redirect_to admin_season_path,
                  notice: "Saison réinitialisée : #{result.deactivated} licence(s) désactivée(s), " \
                          "#{result.kept} conservée(s) (déjà réglée(s) pour la nouvelle saison)."
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user&.admin?
    end
  end
end
