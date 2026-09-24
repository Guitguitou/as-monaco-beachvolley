# frozen_string_literal: true

module Admin
  class SeasonController < BaseController
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
  end
end
