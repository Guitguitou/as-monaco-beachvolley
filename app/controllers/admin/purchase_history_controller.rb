module Admin
  class PurchaseHistoryController < BaseController
    PER_PAGE = 50

    XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

    before_action :require_admin_or_financial_manager!

    def index
      @table = Admin::Tables::Purchases.new
      @state = DataTable::State.new(params)
      purchases = CreditPurchase.left_joins(:pack, :user).includes(:user, :pack, :shop_order)
      @page = Pagination.new(scope: DataTable::Query.call(relation: purchases, definition: @table, state: @state),
                             page: @state.page, per_page: PER_PAGE)

      # Stats (toujours sur tous les achats)
      @total_revenue = CreditPurchase.paid_status.sum(:amount_cents) / 100.0
      @total_purchases = CreditPurchase.count
      @pending_purchases = CreditPurchase.pending_status.count
    end

    def export
      period = CreditPurchases::ExportPeriod.new(params[:start_date], params[:end_date])
      return redirect_to(admin_purchase_history_index_path, alert: period.error) if period.error

      rows = CreditPurchases::ExportTable.new(
        CreditPurchase.includes(:user, :pack, :shop_order).where(created_at: period.range).order(created_at: :asc)
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
