# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_user, only: [:show, :edit, :update, :adjust_credits]

    def index
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
      if @user.update(user_params)
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

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :admin, :coach, :responsable,
        :level_id,
        :password, :password_confirmation
      )
    end

    # Authorization handled by CanCanCan
  end
end
