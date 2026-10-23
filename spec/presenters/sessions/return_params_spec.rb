# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ReturnParams do
  it "keeps the calendar navigation state and drops the blank or unknown values" do
    terrain = FactoryHelpers.resolve_terrain("Terrain 2")
    params = ActionController::Parameters.new(view: "grid", date: "2026-09-21", for_me: "true", terrain: terrain.id.to_s, page: "3")

    expect(described_class.from(params)).to eq({ view: "grid", date: "2026-09-21", for_me: "1", terrain: terrain.id })
  end

  it "turns a legacy terrain name into its id, and drops an unknown one" do
    terrain = FactoryHelpers.resolve_terrain("Terrain 2")

    expect(described_class.from(ActionController::Parameters.new(terrain: "Terrain 2"))).to eq({ terrain: terrain.id })
    expect(described_class.from(ActionController::Parameters.new(terrain: "Terrain 99"))).to eq({})
  end

  it "drops what is missing or invalid" do
    params = ActionController::Parameters.new(view: "list", date: "", for_me: "0")

    expect(described_class.from(params)).to eq({})
  end
end
