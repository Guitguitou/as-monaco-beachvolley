# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditPurchases::ExportPeriod do
  it "covers whole days, and names the export after them" do
    period = described_class.new("2026-09-01", "2026-09-30")

    expect(period.error).to be_nil
    expect(period.range).to eq(Date.new(2026, 9, 1).beginning_of_day..Date.new(2026, 9, 30).end_of_day)
    expect(period.filename("csv")).to eq("achats_20260901_20260930.csv")
  end

  it "asks for two readable dates" do
    expect(described_class.new("", "2026-09-30").error).to eq("Veuillez sélectionner une période valide")
    expect(described_class.new("pas une date", "2026-09-30").error).to eq("Veuillez sélectionner une période valide")
  end

  it "refuses a start after the end" do
    expect(described_class.new("2026-10-01", "2026-09-30").error).to eq("La date de début doit être antérieure à la date de fin")
  end
end
