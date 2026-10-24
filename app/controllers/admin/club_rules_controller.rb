# frozen_string_literal: true

module Admin
  # Édition des règles du club. Les prix sont saisis en euros et stockés en
  # centimes (conversion dans Admin::ClubRulesForm).
  class ClubRulesController < BaseController
    before_action :require_admin!

    def edit
      @form = ClubRulesForm.new(ClubSetting.current)
    end

    def update
      @form = ClubRulesForm.new(ClubSetting.current)
      if @form.save(params.require(:club_rules))
        redirect_to admin_club_rules_path, notice: "Règles du club enregistrées."
      else
        render :edit, status: :unprocessable_content
      end
    end
  end
end
