# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Tables::Purchases do
  let(:zoe) { create(:user, first_name: "Zoé", last_name: "Arnaud") }
  let!(:licence) { create(:credit_purchase, :paid, user: zoe, pack: create(:pack, :licence), amount_cents: 9000, created_at: 2.days.ago) }
  let!(:direct) { create(:credit_purchase, :failed, amount_cents: 1000, created_at: 1.day.ago) }

  def filter(params)
    DataTable::Query.call(relation: CreditPurchase.left_joins(:pack, :user), definition: described_class.new,
                          state: DataTable::State.new(ActionController::Parameters.new(params))).to_a
  end

  it "cherche un joueur et filtre par pack, montant et statut" do
    expect(filter(q: "arnaud")).to eq([ licence ])
    expect(filter(f: { pack_type: "autre" })).to eq([ direct ])
    expect(filter(f: { amount: { from: "50" } })).to eq([ licence ])
    expect(filter(f: { status: [ "failed", "cancelled" ] })).to eq([ direct ])
  end

  it "trie du plus récent au plus ancien par défaut" do
    expect(filter({})).to eq([ direct, licence ])
    expect(filter(quick: "to_check")).to eq([ direct ])
  end
end
