# frozen_string_literal: true

# Notification serveur à serveur de Sherlock's (automaticResponseUrl).
#
# C'est le filet de sécurité du paiement : elle arrive même si le client ferme
# son onglet avant de revenir sur le site. Le traitement est asynchrone et
# idempotent, il peut donc croiser le retour navigateur sans dommage.
class Webhooks::SherlockController < ActionController::API
  def receive
    if params[:Data].blank? || params[:Seal].blank?
      Rails.logger.warn("[Sherlock:webhook] Data ou Seal manquant")
      return head :bad_request
    end

    sherlock_response = Sherlock::Response.from_params(params)

    unless sherlock_response.valid?
      Rails.logger.warn("[Sherlock:webhook] sceau invalide")
      return head :unauthorized
    end

    Rails.logger.info(
      "[Sherlock:webhook] ref=#{sherlock_response.reference} rc=#{sherlock_response.response_code}"
    )
    SherlockCallbackJob.perform_later(sherlock_response.fields)

    head :ok
  rescue StandardError => e
    Rails.logger.error("[Sherlock:webhook] #{e.class}: #{e.message}")
    head :internal_server_error
  end
end
