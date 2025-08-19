# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_user, only: [:show, :edit, :update, :adjust_credits, :disable, :enable]

    def index
      @users = @users.includes(:level)
      if params[:gender].present?
        @users = @users.joins(:level).where(levels: { gender: params[:gender] })
      end
      if params[:license_type].present?
        @users = @users.where(license_type: params[:license_type])
      end
      @users = @users.order(:last_name, :first_name)
    end

    def show
      @balance = @user.balance
      @transactions = @user.credit_transactions.order(created_at: :desc)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      # If no password provided, generate a secure random one
      @user.password = SecureRandom.hex(8) if @user.password.blank?

      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      # Remove blank password fields so Devise doesn't try to reset it
      sanitized_params = user_params.dup
      if sanitized_params[:password].blank?
        sanitized_params.delete(:password)
        sanitized_params.delete(:password_confirmation)
      end

      if @user.update(sanitized_params)
        redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def adjust_credits
      amount = params.require(:adjustment).permit(:amount)[:amount].to_i

      if amount == 0
        redirect_to admin_user_path(@user), alert: "Montant invalide" and return
      end

      CreditTransaction.create!(
        user: @user,
        session: nil,
        transaction_type: :manual_adjustment,
        amount: amount
      )

      # Le solde est recalculé automatiquement par le callback after_commit

      notice = amount.positive? ? "Crédits ajoutés avec succès" : "Crédits déduits avec succès"
      redirect_to admin_user_path(@user), notice: notice
    end

    def disable
      @user.update!(disabled_at: Time.current)
      redirect_to admin_user_path(@user), notice: "Compte désactivé"
    end

    def enable
      @user.update!(disabled_at: nil)
      redirect_to admin_user_path(@user), notice: "Compte réactivé"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :admin, :coach, :responsable,
        :level_id, :license_type,
        :salary_per_training,
        :password, :password_confirmation
      )
    end

    # Authorization handled by CanCanCan
  end
end
