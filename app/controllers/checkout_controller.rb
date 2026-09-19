# frozen_string_literal: true

# Retour de paiement Sherlock's.
#
# LCL renvoie le client en POST cross-site : avec des cookies en SameSite=Lax,
# ni le jeton CSRF ni le cookie de session n'accompagnent cette requête. On
# applique donc le résultat à partir de la réponse signée — qui fait autorité —
# puis on redirige vers un GET, où la session est de nouveau présente et où la
# page de résultat peut être rendue normalement.
class CheckoutController < ApplicationController
  SIGNED_ID_PURPOSE = :checkout
  SIGNED_ID_TTL = 2.hours

  STATUS_TEMPLATES = {
    "paid" => :paid,
    "cancelled" => :cancelled,
    "failed" => :failed
  }.freeze

  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :authenticate_user!, only: [ :create, :show ]

  def create
    sherlock_response = Sherlock::Response.from_params(params)
    return reject("sceau invalide", sherlock_response.reference) unless sherlock_response.valid?

    purchase = CreditPurchase.find_by(sherlock_transaction_reference: sherlock_response.reference)
    return reject("achat introuvable", sherlock_response.reference) unless purchase

    Sherlock::ApplyOutcome.call(purchase: purchase, fields: sherlock_response.fields)

    redirect_to checkout_path(purchase.signed_id(purpose: SIGNED_ID_PURPOSE, expires_in: SIGNED_ID_TTL))
  end

  def show
    @credit_purchase = CreditPurchase.find_signed!(params[:id], purpose: SIGNED_ID_PURPOSE)

    render STATUS_TEMPLATES.fetch(@credit_purchase.status, :pending)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to packs_path, alert: "Ce récapitulatif de paiement n'est plus valable."
  end

  private

  def reject(cause, reference)
    Rails.logger.error("[Sherlock:return] #{cause} ref=#{reference.inspect}")

    redirect_to packs_path,
                alert: "Nous n'avons pas pu vérifier ce retour de paiement. Contacte-nous si tu as été débité."
  end
end
