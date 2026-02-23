# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  def payment_accepted(credit_purchase)
    @credit_purchase = credit_purchase
    @user = credit_purchase.user
    return if @user.nil?

    subject = if credit_purchase.credits_pack? && credit_purchase.credits.to_i.positive?
      "Paiement accepté – #{credit_purchase.credits} crédits reçus"
    else
      "Paiement accepté"
    end
    mail(to: @user.email, subject: subject)
  end
end
