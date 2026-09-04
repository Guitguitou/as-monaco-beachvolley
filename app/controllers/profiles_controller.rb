# frozen_string_literal: true

# « Mon profil » : identité, licence, crédits, encadrement, réglages.
#
# Seul le presenter de l'onglet affiché est instancié. L'ancienne version
# calculait les compteurs et salaires du coach à chaque requête, y compris sur
# un onglet qui ne les affichait pas.
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @tabs = Profile::Tabs.new(user: @user, requested_tab: params[:tab])
    load_active_tab
  end

  def update
    authorize! :update, current_user

    current_user.assign_attributes(profile_params)

    # Contexte :profile_update — exige un nom, sans imposer cette contrainte
    # aux comptes historiques sauvegardés depuis l'administration.
    if current_user.save(context: :profile_update)
      redirect_to profile_path(tab: Profile::Tabs::SETTINGS), notice: "Profil mis à jour."
    else
      @user = current_user
      @tabs = Profile::Tabs.new(user: @user, requested_tab: Profile::Tabs::SETTINGS)
      @settings = Profile::Settings.new(user: @user)
      render :show, status: :unprocessable_content
    end
  end

  private

  def load_active_tab
    case @tabs.active
    when Profile::Tabs::SEASON
      @season = Profile::Season.new(user: @user, page: params[:page], history: params[:history])
    when Profile::Tabs::COACHING
      @coaching = Profile::Coaching.new(user: @user)
    when Profile::Tabs::SETTINGS
      @settings = Profile::Settings.new(user: @user)
    end
  end

  # Liste blanche volontairement minimale.
  #
  # Sont exclus, et doivent le rester : admin, coach, responsable,
  # financial_manager, license_type, next_season_renewed, salary_per_training,
  # activated_at, disabled_at et level_ids. Ces champs ne sont modifiables que
  # par un admin via Admin::UsersController — un utilisateur ne se promeut pas
  # lui-même, ne s'active pas sa licence et ne fixe pas sa rémunération.
  #
  # L'email et le mot de passe restent gérés par Devise
  # (edit_user_registration_path), qui exige le mot de passe courant.
  def profile_params
    params.expect(user: [ :first_name, :last_name ])
  end
end
