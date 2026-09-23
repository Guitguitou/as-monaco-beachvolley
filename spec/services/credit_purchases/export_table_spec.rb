# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditPurchases::ExportTable do
  let(:user) { create(:user, first_name: "Alice", last_name: "Martin", email: "alice@example.com") }
  let(:pack) { create(:pack, name: "Pack 10", pack_type: "credits", credits: 1000) }

  it "lists the headers, one row per purchase, then the totals" do
    paid_at = Time.zone.local(2026, 9, 2, 10, 5, 0)
    purchase = create(:credit_purchase, :paid, user: user, pack: pack, amount_cents: 1500, credits: 1000,
                                               created_at: Time.zone.local(2026, 9, 1, 18, 30, 0), paid_at: paid_at,
                                               sherlock_transaction_reference: "REF42")
    create(:credit_purchase, user: user, pack: create(:pack, pack_type: "equipements", name: "Maillot"), amount_cents: 500, credits: 0)

    rows = described_class.new(CreditPurchase.order(:created_at)).rows

    expect(rows.first).to eq(described_class::HEADERS)
    expect(rows[1]).to eq([ "01/09/2026", "18:30:00", "Alice Martin", "alice@example.com", "Pack 10", "Crédits",
                            15.0, 1000, "Payé", "REF42", "02/09/2026 10:05:00" ])
    expect(rows[2].values_at(5, 7, 8, 10)).to eq([ "Équipements", 0, "En attente", "N/A" ])
    expect(rows[3]).to eq([])
    expect(rows[4]).to eq([ "TOTAL", "", "", "", "", "", 20.0, 1000, "", "", "" ])
    expect(rows[5]).to eq([ "Nombre d'achats", "", "", "", "", "", 2, "", "", "", "" ])
    expect(purchase).to be_paid_status
  end

  it "labels a cancelled purchase" do
    purchase = create(:credit_purchase, user: user, pack: pack, status: "cancelled")

    expect(described_class.new([ purchase ]).rows[1][8]).to eq("Annulé")
  end
end
