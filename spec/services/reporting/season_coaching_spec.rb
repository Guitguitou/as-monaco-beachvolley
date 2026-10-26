# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::SeasonCoaching do
  let(:months) { Reporting::SeasonMonths.new(Season.new(starts_on: Date.new(2026, 9, 1)), today: Date.new(2026, 10, 20)) }
  let(:coach) { create(:user, :coach, salary_per_training_cents: 3000) }

  before do
    [ Time.zone.local(2026, 9, 10, 18), Time.zone.local(2026, 10, 1, 18) ].each do |time|
      create(:session, user: coach, start_at: time, end_at: time + 1.hour)
    end
  end

  it "compte les entraînements et les salaires de chaque coach" do
    coaching = described_class.new(months)

    expect(coaching.rows.map { |row| [ row.coach, row.count, row.amount_eur ] }).to eq([ [ coach, 2, 60 ] ])
    expect(coaching.trainings_by_coach.first[:data].values).to eq([ 1, 1 ])
    expect(coaching.comparisons.second.trend).to eq(:bad)
  end
end
