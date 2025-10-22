class CheckoutController < ApplicationController
  # LCL redirige en POST cross-site (pas de token)
  skip_before_action :verify_authenticity_token, only: [:success, :cancel]
  # Ne force pas la connexion, on affiche juste un message/redirect
  skip_before_action :authenticate_user!, only: [:success, :cancel]

  def success
    # Optionnel: extraire la référence pour log/debug (Data est posté par LCL)
    ref = extract_reference_from(params)
    Rails.logger.info("[Sherlock:success] ref=#{ref} keys=#{params.keys}")

    # UX: on ne crédite pas ici (cela se fait via le webhook automatique)
    flash[:notice] = "Paiement confirmé ✅ Vos crédits arrivent sous peu."
    redirect_to(user_signed_in? ? admin_payments_path : packs_path)
  end

  def cancel
    ref = extract_reference_from(params)
    Rails.logger.info("[Sherlock:cancel] ref=#{ref} keys=#{params.keys}")

    flash[:alert] = "Paiement annulé."
    redirect_to(user_signed_in? ? admin_payments_path : packs_path)
  end

  private

  # "k=v|k=v" -> hash, puis récupère orderId/transactionReference si présent
  def extract_reference_from(params)
    if params[:Data].present?
      h = Sherlock::DataParser.parse(params[:Data])
      h["orderId"] || h["transactionReference"]
    else
      params[:reference] || params[:orderId] || params[:transactionReference]
    end
  end
end
