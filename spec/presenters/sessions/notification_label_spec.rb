# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::NotificationLabel do
  let(:start_at) { Time.zone.local(2030, 3, 14, 19, 30) }

  it "names and dates the session the way notifications and emails say it" do
    label = described_class.new(build(:session, title: "Entraînement G1", start_at: start_at))

    expect([ label.name, label.date, label.time ]).to eq([ "Entraînement G1", "14/03/2030", "19h30" ])
    expect(label.to_s).to eq("Entraînement G1 du 14/03/2030 à 19h30")
  end

  it "falls back to the session type without a title" do
    expect(described_class.new(build(:session, :jeu_libre, title: nil, start_at: start_at)).name).to eq("Jeu libre")
  end
end
