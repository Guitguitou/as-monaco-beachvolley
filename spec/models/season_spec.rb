# frozen_string_literal: true

require "rails_helper"

RSpec.describe Season do
  it "commence au mois de début de saison, avant ou après le Nouvel An" do
    expect(described_class.containing(Date.new(2026, 10, 26), start_month: 9).starts_on).to eq(Date.new(2026, 9, 1))
    expect(described_class.containing(Date.new(2027, 3, 1), start_month: 9).starts_on).to eq(Date.new(2026, 9, 1))
    expect(described_class.containing(Date.new(2026, 8, 31), start_month: 9).starts_on).to eq(Date.new(2025, 9, 1))
  end

  it "dure un an et se nomme par ses deux années" do
    season = described_class.new(starts_on: Date.new(2026, 9, 1))

    expect(season.ends_on).to eq(Date.new(2027, 8, 31))
    expect(season.label).to eq("2026-2027")
    expect(season.months.first(2)).to eq([ Date.new(2026, 9, 1), Date.new(2026, 10, 1) ])
    expect(season.previous.label).to eq("2025-2026")
    expect(described_class.new(starts_on: Date.new(2026, 1, 1)).label).to eq("2026")
  end

  it "suit le mois réglé dans les Règles du club" do
    ClubSetting.current.update!(season_start_month: 1)

    expect(described_class.current.starts_on).to eq(Date.current.beginning_of_year)
  end
end
