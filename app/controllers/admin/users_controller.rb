# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_user, only: %i[show edit update adjust_credits disable enable]

    def index
      result = UserFilterService.new(@users, params).call
      @users = result[:users]
      @per_page = result[:per_page]
      @total_users_count = result[:total_count]
      @total_pages = result[:total_pages]
      @current_page = result[:current_page]
    end

    def show
      @balance = @user.balance
      @transactions = @user.credit_transactions.order(created_at: :desc)
      @active_tab = params[:tab] || "profile"

      # Load coach data if user is a coach
      return unless @user.coach?

      load_coach_data_for_admin

      # Load training data for coaches tab
      return unless @active_tab == "trainings"

      load_coach_trainings_data_for_admin
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      # If no password provided, generate a secure random one
      @user.password = SecureRandom.hex(8) if @user.password.blank?

      # Handle immediate activation checkbox
      @user.activated_at = Time.current if params[:user][:activate_immediately] == "1"

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

      # Handle immediate activation checkbox
      if params[:user][:activate_immediately] == "1" && !@user.activated?
        @user.activated_at = Time.current
      elsif params[:user][:activate_immediately] == "0" && @user.activated?
        # Allow admin to deactivate
        @user.activated_at = nil
      end

      if @user.update(sanitized_params)
        redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def adjust_credits
      amount = params.require(:adjustment).permit(:amount)[:amount].to_i

      redirect_to admin_user_path(@user), alert: "Montant invalide" and return if amount.zero?

      CreditTransaction.create!(
        user: @user,
        session: nil,
        transaction_type: :manual_adjustment,
        amount:
      )

      # Le solde est recalculé automatiquement par le callback after_commit

      notice = amount.positive? ? "Crédits ajoutés avec succès" : "Crédits déduits avec succès"
      redirect_to admin_user_path(@user), notice:
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

    def load_coach_data_for_admin
      coach_data = CoachDataService.new(@user)
      counts = coach_data.training_counts
      salaries = coach_data.salaries

      @my_trainings_week_count = counts[:week]
      @my_trainings_month_count = counts[:month]
      @my_trainings_year_count = counts[:year]
      @my_salary_week = salaries[:week]
      @my_salary_month = salaries[:month]
      @my_salary_year = salaries[:year]
    end

    def load_coach_trainings_data_for_admin
      coach_data = CoachDataService.new(@user)
      @past_trainings = coach_data.past_trainings
      @upcoming_trainings = coach_data.upcoming_trainings
      @monthly_salary_data = coach_data.monthly_salary_data
    end

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :admin, :coach, :responsable, :financial_manager,
        :license_type,
        :salary_per_training,
        :password, :password_confirmation,
        level_ids: []
      )
    end

    # Authorization handled by CanCanCan
  end
end
