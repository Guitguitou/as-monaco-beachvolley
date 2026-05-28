# frozen_string_literal: true

# Previews accessibles sur http://localhost:3000/rails/mailers/payment_mailer
class PaymentMailerPreview < ActionMailer::Preview
  def payment_accepted_credits_pack
    PaymentMailer.payment_accepted(credits_pack_purchase)
  end

  def payment_accepted_non_pack
    PaymentMailer.payment_accepted(non_pack_purchase)
  end

  private

  def credits_pack_purchase
    pack = Pack.new(
      name: "Pack 500 crédits",
      pack_type: "credits",
      credits: 500,
      amount_cents: 500
    )
    pack.id = 1

    purchase = CreditPurchase.new(
      user: preview_user,
      pack: pack,
      credits: 500,
      amount_cents: 500,
      currency: "EUR",
      status: "paid",
      sherlock_transaction_reference: "CP-PREVIEW-CREDITS"
    )
    purchase.id = 1
    purchase
  end

  def non_pack_purchase
    purchase = CreditPurchase.new(
      user: preview_user,
      pack: nil,
      amount_cents: 2500,
      currency: "EUR",
      status: "paid",
      sherlock_transaction_reference: "CP-PREVIEW-NONPACK"
    )
    purchase.id = 2
    purchase
  end

  def preview_user
    User.first || begin
      user = User.new(
        first_name: "Alice",
        last_name: "Preview",
        email: "preview@example.com"
      )
      user.id = 1
      user
    end
  end
end
