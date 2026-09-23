# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::SessionType do
  it "describes each session type" do
    training = described_class.for("entrainement")

    expect([ training.label, training.icon, training.classes ]).to eq([ "Entraînement", "dumbbell", "bg-green-100 text-green-800" ])
    expect(described_class.for("coaching_prive").label).to eq("Coaching privé")
  end

  it "falls back to a neutral look for an unknown type" do
    other = described_class.for("beach_party")

    expect([ other.label, other.icon, other.classes ]).to eq([ "Beach party", "volleyball", "bg-gray-100 text-gray-800" ])
  end
end
