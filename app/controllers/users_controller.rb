class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @balance = @user.balance
    @transactions = @user.credit_transactions.order(created_at: :desc)
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :level_id)
  end
end
