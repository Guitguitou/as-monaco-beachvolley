# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::DefaultEndAt do
  it "ends a training, free play or private coaching 90 minutes after its start" do
    attributes = described_class.fill({ session_type: "jeu_libre", start_at: "2030-03-14T18:00", end_at: "" })

    expect(attributes[:end_at]).to eq(Time.zone.parse("2030-03-14T19:30"))
  end

  it "keeps a given end" do
    attributes = described_class.fill({ session_type: "entrainement", start_at: "2030-03-14T18:00", end_at: "2030-03-14T20:00" })

    expect(attributes[:end_at]).to eq("2030-03-14T20:00")
  end

  it "leaves the other types and unreadable starts alone" do
    expect(described_class.fill({ session_type: "tournoi", start_at: "2030-03-14T18:00" })[:end_at]).to be_nil
    expect(described_class.fill({ session_type: "jeu_libre", start_at: "n'importe quoi" })[:end_at]).to be_nil
  end
end
