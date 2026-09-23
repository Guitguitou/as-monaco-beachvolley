module Admin
  class PurchaseHistoryController < BaseController
    STATUS_FILTERS = { "paid" => %w[paid], "pending" => %w[pending], "failed" => %w[failed cancelled] }.freeze

    XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

    before_action :require_admin_or_financial_manager!

    def index
      base_scope = CreditPurchase.includes(:user, :pack).order(created_at: :desc)

      @status_filter = params[:status].to_s
      statuses = STATUS_FILTERS[@status_filter]
      @credit_purchases = (statuses ? base_scope.where(status: statuses) : base_scope).limit(100)

      # Stats (toujours sur tous les achats)
      @total_revenue = CreditPurchase.paid_status.sum(:amount_cents) / 100.0
      @total_purchases = CreditPurchase.count
      @pending_purchases = CreditPurchase.pending_status.count
    end

    def export
      period = CreditPurchases::ExportPeriod.new(params[:start_date], params[:end_date])
      return redirect_to(admin_purchase_history_index_path, alert: period.error) if period.error

      rows = CreditPurchases::ExportTable.new(
        CreditPurchase.includes(:user, :pack).where(created_at: period.range).order(created_at: :asc)
      ).rows
      # Ne pas utiliser `params[:format]` seul : réservé à la négociation MIME Rails (406 / formats inconnus).
      case params[:export_format].to_s.presence || params[:format].to_s.presence || "csv"
      when "csv" then export_csv(rows, period.filename("csv"))
      when "xlsx" then export_xlsx(rows, period.filename("xlsx"))
      else redirect_to admin_purchase_history_index_path, alert: "Format d'export non supporté"
      end
    end

    private

    def export_csv(rows, filename)
      require "csv"

      response.headers["Content-Type"] = "text/csv; charset=utf-8"
      response.headers["Content-Disposition"] = %(attachment; filename="#{filename}")
      render plain: CSV.generate(headers: true, encoding: "UTF-8") { |csv| rows.each { |row| csv << row } }
    end

    def export_xlsx(rows, filename)
      require "axlsx"

      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Achats") { |sheet| rows.each { |row| sheet.add_row(row) } }
      send_data package.to_stream.read, filename: filename, type: XLSX_MIME, disposition: "attachment"
    end
  end
end
