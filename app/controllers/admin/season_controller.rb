# frozen_string_literal: true

module Admin
  class SeasonController < BaseController
    before_action :require_admin!

    def show
      @activated_count = User.activated.count
      @renewed_count = User.activated.renewed_for_next_season.count
      @to_deactivate_count = @activated_count - @renewed_count
      @club_setting = ClubSetting.current
    end

    def update
      @club_setting = ClubSetting.current
      if @club_setting.update(params.require(:club_setting).permit(:membership_form_url))
        redirect_to admin_season_path, notice: "Lien du formulaire d'adhésion enregistré."
      else
        redirect_to admin_season_path, alert: @club_setting.errors.full_messages.to_sentence
      end
    end

    def reset
      result = Licenses::ResetSeason.call

      redirect_to admin_season_path,
                  notice: "Saison réinitialisée : #{result.deactivated} licence(s) désactivée(s), " \
                          "#{result.kept} conservée(s) (déjà réglée(s) pour la nouvelle saison)."
    end

    private
  end
end
