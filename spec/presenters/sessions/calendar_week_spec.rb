# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CalendarWeek do
  it "starts on the monday of the given day" do
    expect(described_class.new("2030-03-14").start_on).to eq(Date.new(2030, 3, 11))
  end

  it "shows the current week without a readable date" do
    monday = Time.zone.today.beginning_of_week(:monday)

    expect(described_class.new(nil).start_on).to eq(monday)
    expect(described_class.new("pas une date").start_on).to eq(monday)
  end

  it "lists the terrain closures of the week" do
    closure = TerrainClosure.create!(terrain: "Terrain 2", starts_on: Date.new(2030, 3, 13), ends_on: Date.new(2030, 3, 20), reason: "Travaux")
    TerrainClosure.create!(terrain: "Terrain 1", starts_on: Date.new(2030, 4, 1), ends_on: Date.new(2030, 4, 2), reason: "Tournoi")

    expect(described_class.new("2030-03-14").closures).to eq([ closure ])
  end
end
