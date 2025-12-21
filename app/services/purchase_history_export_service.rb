# frozen_string_literal: true

# Service to export purchase history to CSV format
class PurchaseHistoryExportService
  def initialize(purchases, start_date, end_date)
    @purchases = purchases
    @start_date = start_date
    @end_date = end_date
  end

  def call
    require "csv"

    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << csv_headers
      @purchases.each { |purchase| csv << csv_row_for(purchase) }
      csv << []
      csv << csv_totals_row
      csv << csv_count_row
    end
  end

  def filename
    "achats_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.csv"
  end

  private

  def csv_headers
    [
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
    ]
  end

  def csv_row_for(purchase)
    [
      format_date(purchase.created_at),
      format_time(purchase.created_at),
      user_name(purchase.user),
      user_email(purchase.user),
      pack_name(purchase.pack),
      pack_type_label(purchase.pack),
      purchase.amount_eur,
      purchase.credits || 0,
      status_label(purchase.status),
      transaction_reference(purchase),
      format_paid_at(purchase.paid_at)
    ]
  end

  def format_date(datetime)
    datetime.strftime("%d/%m/%Y")
  end

  def format_time(datetime)
    datetime.strftime("%H:%M:%S")
  end

  def user_name(user)
    user&.full_name || "Utilisateur anonyme"
  end

  def user_email(user)
    user&.email || "N/A"
  end

  def pack_name(pack)
    pack&.name || "Achat direct"
  end

  def transaction_reference(purchase)
    purchase.sherlock_transaction_reference || "N/A"
  end

  def format_paid_at(paid_at)
    paid_at&.strftime("%d/%m/%Y %H:%M:%S") || "N/A"
  end

  def csv_totals_row
    total_amount = @purchases.sum { |p| p.amount_eur || 0 }
    total_credits = @purchases.sum { |p| p.credits || 0 }
    [ "TOTAL", "", "", "", "", "", total_amount, total_credits, "", "", "" ]
  end

  def csv_count_row
    [ "Nombre d'achats", "", "", "", "", "", @purchases.count, "", "", "", "" ]
  end

  def status_label(status)
    case status
    when "paid" then "Payé"
    when "pending" then "En attente"
    when "failed" then "Échoué"
    when "cancelled" then "Annulé"
    else status
    end
  end

  def pack_type_label(pack)
    case pack&.pack_type
    when "credits" then "Crédits"
    when "licence" then "Licence"
    when "stage" then "Stage"
    else "N/A"
    end
  end
end
