# frozen_string_literal: true

# Présentation des mouvements de crédits et des achats.
#
# Le signe, la couleur et la variante de badge étaient calculés en ligne dans
# users/_profile_tab, et à recopier dès qu'un mouvement s'affichait ailleurs
# (tableau desktop et liste mobile de l'historique, par exemple).
module CreditsHelper
  # « +12 » / « -3 » : le signe est porté par la valeur, pas par la couleur seule.
  def signed_credits(amount)
    amount = amount.to_i
    amount.positive? ? "+#{amount}" : amount.to_s
  end

  def credit_amount_class(amount)
    amount.to_i.negative? ? "text-red-600" : "text-green-600"
  end

  def credit_transaction_badge_variant(transaction_type)
    case transaction_type.to_s
    when "purchase" then :purple
    when "refund" then :success
    when "manual_adjustment" then :info
    else :neutral
    end
  end

  # Statut d'un achat, dans le vocabulaire du joueur.
  def credit_purchase_status_label(status)
    case status.to_s
    when "paid" then "Payé"
    when "pending" then "En attente"
    when "failed" then "Échoué"
    when "cancelled" then "Annulé"
    else status.to_s.humanize
    end
  end

  def credit_purchase_status_variant(status)
    case status.to_s
    when "paid" then :success
    when "pending" then :warning
    when "failed", "cancelled" then :danger
    else :neutral
    end
  end

  # Montant d'un achat, stocké en centimes.
  def purchase_amount(purchase)
    number_to_currency(purchase.amount_cents.to_i / 100.0, unit: "€", format: "%n %u", precision: 2)
  end
end
