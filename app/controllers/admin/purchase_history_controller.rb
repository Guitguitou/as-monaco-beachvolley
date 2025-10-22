module Admin
  class PurchaseHistoryController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      @credit_purchases = CreditPurchase.includes(:user, :pack)
                                        .order(created_at: :desc)
                                        .limit(100)
      
      # Stats
      @total_revenue = CreditPurchase.paid_status.sum(:amount_cents) / 100.0
      @total_purchases = CreditPurchase.count
      @pending_purchases = CreditPurchase.pending_status.count
    end

    private

    def ensure_admin!
      redirect_to root_path, alert: "Accès interdit" unless current_user.admin?
    end
  end
end
