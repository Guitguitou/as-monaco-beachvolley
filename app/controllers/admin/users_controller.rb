# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_user, only: [:show, :edit, :update]

    def index
      @users = User.order(:last_name, :first_name)
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.password = SecureRandom.hex(8)

      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :admin, :coach, :responsable,
        :level_id
      )
    end

    def require_admin!
      redirect_to root_path, alert: "Accès réservé" unless current_user.admin?
    end
  end
end
