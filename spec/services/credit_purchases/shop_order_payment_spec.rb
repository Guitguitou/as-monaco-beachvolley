# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Paiement d'une commande d'équipements" do
  let(:order) { create(:shop_order, status: "awaiting_payment") }
  let(:purchase) { create(:credit_purchase, user: order.user, pack: nil, shop_order: order, credits: 0, amount_cents: 1800) }

  it "passe la commande en payée et lui donne un numéro" do
    travel_to(Time.zone.local(2026, 11, 5, 10)) { CreditPurchases::ProcessPayment.call(purchase: purchase) }

    expect(order.reload).to be_paid_status
    expect(order.paid_at).to eq(Time.zone.local(2026, 11, 5, 10))
    expect(order.number).to eq(format("CMD-2026-%04d", order.id))
    expect(purchase.reload).to be_paid_status
  end
end
