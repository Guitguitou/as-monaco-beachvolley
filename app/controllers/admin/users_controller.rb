# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    load_and_authorize_resource
    before_action :set_user, only: %i[show edit update adjust_credits disable enable]

    PER_PAGE = 25

    def index
      users = Users::AdminFilterQuery.call(relation: @users, params: params)
      page = Pagination.new(scope: users.includes(:levels), page: params[:page], per_page: PER_PAGE)
      @users = page.records
      @total_pages = page.total_pages
      @current_page = page.current_page
    end

    def show
      @balance = @user.balance
      @transactions = @user.credit_transactions.order(created_at: :desc)
      @active_tab = params[:tab] || "profile"

      # Bilan coach : le presenter ne requête que ce que la vue lit.
      @report = Coach::TrainingsReport.new(coach: @user) if @user.coach?
    end

    def new
      @user = User.new
    end

    def create
      @user = Users::AdminAttributes.apply(User.new, user_params, activate: params[:user][:activate_immediately])

      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      Users::AdminAttributes.apply(@user, user_params, activate: params[:user][:activate_immediately])

      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def adjust_credits
      amount = params.require(:adjustment).permit(:amount)[:amount].to_i

      redirect_to admin_user_path(@user), alert: "Montant invalide" and return if amount.zero?

      CreditTransaction.record!(
        user: @user,
        session: nil,
        transaction_type: :manual_adjustment,
        amount: amount
      )

      notice = amount.positive? ? "Cr\u00E9dits ajout\u00E9s avec succ\u00E8s" : "Cr\u00E9dits d\u00E9duits avec succ\u00E8s"
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

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :admin, :coach, :responsable, :financial_manager,
        :license_type,
        :next_season_renewed,
        :salary_per_training,
        :password, :password_confirmation,
        level_ids: []
      )
    end

    # Authorization handled by CanCanCan
  end
end
