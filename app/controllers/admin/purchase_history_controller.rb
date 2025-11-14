module Admin
  class PurchaseHistoryController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      base_scope = CreditPurchase.includes(:user, :pack).order(created_at: :desc)
      
      # Filtrer par statut si présent
      @status_filter = params[:status].to_s
      case @status_filter
      when 'paid'
        @credit_purchases = base_scope.paid_status.limit(100)
      when 'pending'
        @credit_purchases = base_scope.pending_status.limit(100)
      when 'failed'
        @credit_purchases = base_scope.where(status: ['failed', 'cancelled']).limit(100)
      else
        # Par défaut, tous les achats
        @credit_purchases = base_scope.limit(100)
      end
      
      # Stats (toujours sur tous les achats)
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
