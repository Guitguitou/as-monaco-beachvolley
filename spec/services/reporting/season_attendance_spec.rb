# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::SeasonAttendance do
  let(:season) { Season.new(starts_on: Date.new(2026, 9, 1)) }
  let(:months) { Reporting::SeasonMonths.new(season, today: Date.new(2026, 10, 20)) }
  let(:coach) { create(:user, :coach) }

  def session_on(time, **attributes)
    create(:session, user: coach, start_at: time, end_at: time + 1.hour, max_players: 4, **attributes)
  end

  before do
    september = session_on(Time.zone.local(2026, 9, 10, 18))
    create_list(:registration, 2, session: september, status: :confirmed)
    october = session_on(Time.zone.local(2026, 10, 5, 18), session_type: "jeu_libre")
    create(:registration, session: october, status: :confirmed)
    last_season = session_on(Time.zone.local(2025, 9, 12, 18))
    create(:registration, session: last_season, status: :confirmed)
  end

  it "compte les participations par type et par mois de la saison" do
    series = described_class.new(months).participations_by_type

    expect(series.first[:data].values).to eq([ 2, 0 ])
    expect(series.second).to include(name: "Jeu libre", data: include(I18n.l(Date.new(2026, 10, 1), format: "%b %y") => 1))
  end

  it "compare à la saison précédente à date égale" do
    participations = described_class.new(months).comparisons.first

    expect([ participations.current, participations.previous ]).to eq([ 3, 1 ])
  end

  it "calcule le remplissage par mois" do
    expect(described_class.new(months).fill_rate_by_month.values).to eq([ 50, 25 ])
  end
end
