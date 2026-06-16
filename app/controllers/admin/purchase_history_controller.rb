module Admin
  class PurchaseHistoryController < ApplicationController
    PURCHASE_EXPORT_HEADERS = [
      "Date",
      "Heure",
      "Utilisateur",
      "Email",
      "Pack",
      "Type de pack",
      "Montant (€)",
      "Crédits",
      "Statut",
      "Référence transaction",
      "Date de paiement"
    ].freeze

    XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

    layout "dashboard"
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      base_scope = CreditPurchase.includes(:user, :pack).order(created_at: :desc)

      # Filtrer par statut si présent
      @status_filter = params[:status].to_s
      case @status_filter
      when "paid"
        @credit_purchases = base_scope.paid_status.limit(100)
      when "pending"
        @credit_purchases = base_scope.pending_status.limit(100)
      when "failed"
        @credit_purchases = base_scope.where(status: [ "failed", "cancelled" ]).limit(100)
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
      # Ne pas utiliser `params[:format]` seul : réservé à la négociation MIME Rails (406 / formats inconnus).
      export_format = params[:export_format].to_s.presence || params[:format].to_s.presence || "csv"

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

      case export_format
      when "csv"
        export_csv(purchases, start_date, end_date)
      when "xlsx"
        export_xlsx(purchases, start_date, end_date)
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
      require "csv"

      filename = export_filename_base(start_date, end_date) + ".csv"

      response.headers["Content-Type"] = "text/csv; charset=utf-8"
      response.headers["Content-Disposition"] = %(attachment; filename="#{filename}")

      csv_data = CSV.generate(headers: true, encoding: "UTF-8") do |csv|
        csv << PURCHASE_EXPORT_HEADERS
        purchases.each { |purchase| csv << purchase_row_cells(purchase) }
        csv << []
        csv << total_row_cells(purchases)
        csv << count_row_cells(purchases)
      end

      render plain: csv_data
    end

    def export_xlsx(purchases, start_date, end_date)
      require "axlsx"

      filename = export_filename_base(start_date, end_date) + ".xlsx"
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Achats") do |sheet|
        sheet.add_row(PURCHASE_EXPORT_HEADERS)
        purchases.each { |purchase| sheet.add_row(purchase_row_cells(purchase)) }
        sheet.add_row([])
        sheet.add_row(total_row_cells(purchases))
        sheet.add_row(count_row_cells(purchases))
      end

      send_data package.to_stream.read,
                filename: filename,
                type: XLSX_MIME,
                disposition: "attachment"
    end

    def export_filename_base(start_date, end_date)
      "achats_#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"
    end

    def purchase_row_cells(purchase)
      [
        purchase.created_at.strftime("%d/%m/%Y"),
        purchase.created_at.strftime("%H:%M:%S"),
        purchase.user&.full_name || "Utilisateur anonyme",
        purchase.user&.email || "N/A",
        purchase.pack&.name || "Achat direct",
        pack_type_label_for(purchase),
        purchase.amount_eur,
        purchase.credits || 0,
        status_label_for(purchase),
        purchase.sherlock_transaction_reference || "N/A",
        purchase.paid_at&.strftime("%d/%m/%Y %H:%M:%S") || "N/A"
      ]
    end

    def status_label_for(purchase)
      case purchase.status
      when "paid" then "Payé"
      when "pending" then "En attente"
      when "failed" then "Échoué"
      when "cancelled" then "Annulé"
      else purchase.status
      end
    end

    def pack_type_label_for(purchase)
      case purchase.pack&.pack_type
      when "credits" then "Crédits"
      when "licence" then "Licence"
      when "stage" then "Stage"
      when "inscription_tournoi" then "Inscription tournoi"
      when "equipements" then "Équipements"
      else
        if purchase.pack&.pack_type.present?
          purchase.pack.pack_type.humanize
        else
          "N/A"
        end
      end
    end

    def total_row_cells(purchases)
      total_amount = purchases.sum { |p| p.amount_eur || 0 }
      total_credits = purchases.sum { |p| p.credits || 0 }
      [ "TOTAL", "", "", "", "", "", total_amount, total_credits, "", "", "" ]
    end

    def count_row_cells(purchases)
      [ "Nombre d'achats", "", "", "", "", "", purchases.count, "", "", "", "" ]
    end
  end
end
