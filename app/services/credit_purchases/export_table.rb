# frozen_string_literal: true

module CreditPurchases
  # Tableau d'export des achats, identique en CSV et en XLSX : en-têtes, une
  # ligne par achat, puis le total et le nombre d'achats.
  class ExportTable
    HEADERS = [
      "Date", "Heure", "Utilisateur", "Email", "Pack", "Type de pack", "Montant (€)",
      "Crédits", "Statut", "Référence transaction", "Date de paiement"
    ].freeze

    STATUS_LABELS = { "paid" => "Payé", "pending" => "En attente", "failed" => "Échoué", "cancelled" => "Annulé" }.freeze
    PACK_TYPE_LABELS = {
      "credits" => "Crédits", "licence" => "Licence", "stage" => "Stage",
      "inscription_tournoi" => "Inscription tournoi", "equipements" => "Équipements"
    }.freeze

    def initialize(purchases)
      @purchases = purchases.to_a
    end

    def rows
      [ HEADERS, *@purchases.map { |purchase| row(purchase) }, [], total_row, count_row ]
    end

    private

    def row(purchase)
      [
        purchase.created_at.strftime("%d/%m/%Y"),
        purchase.created_at.strftime("%H:%M:%S"),
        purchase.user.full_name,
        purchase.user.email,
        purchase.pack&.name || "Achat direct",
        pack_type_label(purchase.pack&.pack_type),
        purchase.amount_eur,
        purchase.credits,
        STATUS_LABELS.fetch(purchase.status, purchase.status),
        purchase.sherlock_transaction_reference || "N/A",
        purchase.paid_at&.strftime("%d/%m/%Y %H:%M:%S") || "N/A"
      ]
    end

    def pack_type_label(pack_type)
      return "N/A" if pack_type.blank?

      PACK_TYPE_LABELS.fetch(pack_type, pack_type.humanize)
    end

    def total_row
      summary_row("TOTAL", @purchases.sum(&:amount_eur), @purchases.sum(&:credits))
    end

    def count_row
      summary_row("Nombre d'achats", @purchases.size, "")
    end

    def summary_row(label, amount, credits)
      [ label, "", "", "", "", "", amount, credits, "", "", "" ]
    end
  end
end
