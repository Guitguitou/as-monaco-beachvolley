# frozen_string_literal: true

# Clôture les achats restés en attente.
#
# Un achat `pending` correspond à un client qui n'est jamais revenu de la page
# de paiement et pour lequel LCL n'a rien notifié. Passé l'expiration de la
# session Sherlock's, plus aucune réponse n'arrivera : les laisser en attente
# rend la file des paiements illisible et empêche de repérer un vrai incident.
class ExpireStalePurchasesJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 2.hours

  def perform
    stale_purchases.find_each do |purchase|
      purchase.mark_as_abandoned!
      Rails.logger.info("[Sherlock] achat abandonné #{purchase.sherlock_transaction_reference}")
    end
  end

  private

  def stale_purchases
    CreditPurchase.pending_status.where(created_at: ..STALE_AFTER.ago)
  end
end
