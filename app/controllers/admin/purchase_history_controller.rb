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

    def export
      start_date = parse_date(params[:start_date])
      end_date = parse_date(params[:end_date])
      format = params[:format] || 'csv'

      # Validation des dates
      if start_date.nil? || end_date.nil?
        redirect_to admin_purchase_history_index_path, alert: "Veuillez sélectionner une période valide"
        return
      end

      if start_date > end_date
        redirect_to admin_purchase_history_index_path, alert: "La date de début doit être antérieure à la date de fin"
        return
      end

      # Récupérer les achats de la période
      purchases = CreditPurchase.includes(:user, :pack)
                                 .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                 .order(created_at: :asc)

      case format
      when 'csv'
        export_csv(purchases, start_date, end_date)
      else
        redirect_to admin_purchase_history_index_path, alert: "Format d'export non supporté"
      end
    end

    private

    def ensure_admin!
      redirect_to root_path, alert: "Accès interdit" unless current_user.admin? || current_user.financial_manager?
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Date.parse(date_string)
    rescue ArgumentError
      nil
    end

    def export_csv(purchases, start_date, end_date)
      require 'csv'

      filename = "achats_#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}.csv"

      response.headers['Content-Type'] = 'text/csv; charset=utf-8'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""

      csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
        # En-têtes
        csv << [
          'Date',
          'Heure',
          'Utilisateur',
          'Email',
          'Pack',
          'Type de pack',
          'Montant (€)',
          'Crédits',
          'Statut',
          'Référence transaction',
          'Date de paiement'
        ]

        # Données
        purchases.each do |purchase|
          status_label = case purchase.status
                        when 'paid' then 'Payé'
                        when 'pending' then 'En attente'
                        when 'failed' then 'Échoué'
                        when 'cancelled' then 'Annulé'
                        else purchase.status
                        end

          pack_type_label = case purchase.pack&.pack_type
                           when 'credits' then 'Crédits'
                           when 'licence' then 'Licence'
                           when 'stage' then 'Stage'
                           else 'N/A'
                           end

          csv << [
            purchase.created_at.strftime('%d/%m/%Y'),
            purchase.created_at.strftime('%H:%M:%S'),
            purchase.user&.full_name || 'Utilisateur anonyme',
            purchase.user&.email || 'N/A',
            purchase.pack&.name || 'Achat direct',
            pack_type_label,
            purchase.amount_eur,
            purchase.credits || 0,
            status_label,
            purchase.sherlock_transaction_reference || 'N/A',
            purchase.paid_at&.strftime('%d/%m/%Y %H:%M:%S') || 'N/A'
          ]
        end

        # Ligne de total
        csv << []
        total_amount = purchases.sum { |p| p.amount_eur || 0 }
        total_credits = purchases.sum { |p| p.credits || 0 }
        csv << ['TOTAL', '', '', '', '', '', total_amount, total_credits, '', '', '']
        csv << ['Nombre d\'achats', '', '', '', '', '', purchases.count, '', '', '', '']
      end

      render plain: csv_data
    end
  end
end
