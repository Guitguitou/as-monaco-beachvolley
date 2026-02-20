# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  def payment_accepted(credit_purchase)
    @credit_purchase = credit_purchase
    @user = credit_purchase.user
    return if @user.nil?

    mail(
      to: @user.email,
      subject: "Paiement accepté – #{credit_purchase.credits} crédits reçus"
    )
  end
end
