# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::Schedule do
  let(:start_at) { Time.zone.local(2030, 3, 14, 19, 30) }
  let(:session_record) { build(:session, title: "Entraînement G1", terrain: "Terrain 2", start_at: start_at, end_at: start_at + 90.minutes) }
  let(:schedule) { described_class.new(session_record) }

  it "names the session by its title" do
    expect(schedule.title).to eq("Entraînement G1")
  end

  it "falls back to the display name without a title" do
    session_record.title = ""
    allow(session_record).to receive(:display_name).and_return("Jeu libre")

    expect(schedule.title).to eq("Jeu libre")
  end

  it "formats the day and the time range" do
    expect(schedule.day_label).to eq(I18n.l(start_at.to_date, format: :day_and_month))
    expect(schedule.time_range).to eq("19:30 – 21:00")
  end

  it "keeps only the terrain name" do
    expect(schedule.terrain_label).to eq("Terrain 2")
  end
end
