# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataTable::Filters do
  let!(:old) { create(:credit_purchase, created_at: Time.zone.local(2026, 9, 1, 10), amount_cents: 1000) }
  let!(:recent) { create(:credit_purchase, created_at: Time.zone.local(2026, 10, 15, 23, 30), amount_cents: 2500) }

  it "filtre une plage de dates, jours bornes inclus en entier" do
    filter = DataTable::Filters::DateRange.new("credit_purchases.created_at")

    expect(filter.apply(CreditPurchase.all, { "from" => "2026-10-15" })).to eq([ recent ])
    expect(filter.apply(CreditPurchase.all, { "to" => "2026-10-15" }).count).to eq(2)
    expect(filter.apply(CreditPurchase.all, { "from" => "n'importe quoi" }).count).to eq(2)
    expect(filter.apply(CreditPurchase.all, "2026-10-15").count).to eq(2)
  end

  it "filtre une plage numérique saisie en euros sur des centimes" do
    filter = DataTable::Filters::NumberRange.new("credit_purchases.amount_cents", scale: 100)

    expect(filter.apply(CreditPurchase.all, { "from" => "20,5" })).to eq([ recent ])
    expect(filter.apply(CreditPurchase.all, { "to" => "10" })).to eq([ old ])
  end

  it "ignore une valeur vide" do
    expect(DataTable::Filters::Text.new("credit_purchases.status").apply(CreditPurchase.all, "").count).to eq(2)
    expect(DataTable::Filters::Boolean.new("credit_purchases.id").active?(nil)).to be(false)
  end
end
