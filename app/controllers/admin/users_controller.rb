# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_user, only: %i[show edit update adjust_credits disable enable]

    PER_PAGE = 25

    def index
      @users = @users

      # Search by name or email
      if params[:q].present?
        query = "%#{params[:q].strip}%"
        @users = @users.where(
          User.arel_table[:first_name].matches(query)
          .or(User.arel_table[:last_name].matches(query))
          .or(User.arel_table[:email].matches(query))
        )
      end

      @users = @users.joins(:levels).where(levels: { gender: params[:gender] }).distinct if params[:gender].present?

      @users = @users.where(license_type: params[:license_type]) if params[:license_type].present?

      # Sorting
      allowed_sorts = {
        'name' => ['last_name ASC, first_name ASC', 'last_name DESC, first_name DESC'],
        'email' => ['email ASC', 'email DESC'],
        'license_type' => ['license_type ASC', 'license_type DESC']
      }
      sort_key = params[:sort].to_s
      direction = params[:direction] == 'desc' ? 1 : 0
      @users = if allowed_sorts.key?(sort_key)
                 @users.order(Arel.sql(allowed_sorts[sort_key][direction]))
               else
                 # Default stable ordering for pagination
                 @users.order(:last_name, :first_name)
               end

      # Pagination (25 per page)
      @per_page = PER_PAGE
      @total_users_count = @users.count
      @total_pages = (@total_users_count.to_f / @per_page).ceil

      requested_page = params.fetch(:page, 1).to_i
      @current_page = [requested_page, 1].max
      # Ensure current page stays within bounds (handle empty collections too)
      upper_bound = [@total_pages, 1].max
      @current_page = [@current_page, upper_bound].min

      offset = (@current_page - 1) * @per_page
      @users = @users.limit(@per_page).offset(offset).includes(:levels)
    end

    def show
      @balance = @user.balance
      @transactions = @user.credit_transactions.order(created_at: :desc)
      @active_tab = params[:tab] || 'profile'

      # Load coach data if user is a coach
      return unless @user.coach?

      load_coach_data_for_admin

      # Load training data for coaches tab
      return unless @active_tab == 'trainings'

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
      @user.activated_at = Time.current if params[:user][:activate_immediately] == '1'

      if @user.save
        redirect_to admin_user_path(@user), notice: 'Utilisateur créé avec succès'
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
      if params[:user][:activate_immediately] == '1' && !@user.activated?
        @user.activated_at = Time.current
      elsif params[:user][:activate_immediately] == '0' && @user.activated?
        # Allow admin to deactivate
        @user.activated_at = nil
      end

      if @user.update(sanitized_params)
        redirect_to admin_user_path(@user), notice: 'Utilisateur mis à jour'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def adjust_credits
      amount = params.require(:adjustment).permit(:amount)[:amount].to_i

      redirect_to admin_user_path(@user), alert: 'Montant invalide' and return if amount.zero?

      CreditTransaction.create!(
        user: @user,
        session: nil,
        transaction_type: :manual_adjustment,
        amount:
      )

      # Le solde est recalculé automatiquement par le callback after_commit

      notice = amount.positive? ? 'Crédits ajoutés avec succès' : 'Crédits déduits avec succès'
      redirect_to admin_user_path(@user), notice:
    end

    def disable
      @user.update!(disabled_at: Time.current)
      redirect_to admin_user_path(@user), notice: 'Compte désactivé'
    end

    def enable
      @user.update!(disabled_at: nil)
      redirect_to admin_user_path(@user), notice: 'Compte réactivé'
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def load_coach_data_for_admin
      week_range  = Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
      month_range = Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
      year_range  = Time.zone.now.beginning_of_year..Time.zone.now.end_of_year

      @my_trainings_week_count  = Session.where(user_id: @user.id, session_type: 'entrainement',
                                                start_at: week_range).count
      @my_trainings_month_count = Session.where(user_id: @user.id, session_type: 'entrainement',
                                                start_at: month_range).count
      @my_trainings_year_count  = Session.where(user_id: @user.id, session_type: 'entrainement',
                                                start_at: year_range).count

      spt = @user.salary_per_training
      @my_salary_week  = (@my_trainings_week_count  * spt).to_f
      @my_salary_month = (@my_trainings_month_count * spt).to_f
      @my_salary_year  = (@my_trainings_year_count  * spt).to_f
    end

    def load_coach_trainings_data_for_admin
      # Past trainings with details
      @past_trainings = Session.includes(:levels, :registrations)
                               .where(user_id: @user.id, session_type: 'entrainement')
                               .where('start_at < ?', Time.current)
                               .order(start_at: :desc)
                               .limit(50)

      # Upcoming trainings
      @upcoming_trainings = Session.includes(:levels, :registrations)
                                   .where(user_id: @user.id, session_type: 'entrainement')
                                   .where('start_at >= ?', Time.current)
                                   .order(start_at: :asc)
                                   .limit(20)

      # Monthly salary data for the last 12 months
      @monthly_salary_data = []
      12.times do |i|
        month_start = (Time.current - i.months).beginning_of_month
        month_end = month_start.end_of_month

        training_count = Session.where(
          user_id: @user.id,
          session_type: 'entrainement',
          start_at: month_start..month_end
        ).count

        total_salary = training_count * @user.salary_per_training

        @monthly_salary_data << {
          month_name: month_start.strftime('%B %Y'),
          training_count:,
          total_salary:
        }
      end
      @monthly_salary_data.reverse! # Show oldest to newest
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
