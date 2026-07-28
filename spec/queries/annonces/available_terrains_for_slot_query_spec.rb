require 'rails_helper'

RSpec.describe Annonces::AvailableTerrainsForSlotQuery do
  let(:start_at) { (Time.current + 2.days).change(hour: 19, min: 0) }
  let(:slot) { build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) }

  it "retourne tous les terrains quand aucun n'est occupé" do
    expect(described_class.call(slot: slot)).to match_array(Session.terrains.keys)
  end

  it "exclut un terrain occupé par une session chevauchante" do
    create(:session, :jeu_libre, terrain: "Terrain 1", start_at: start_at, end_at: start_at + 2.hours)
    expect(described_class.call(slot: slot)).not_to include("Terrain 1")
    expect(described_class.call(slot: slot)).to include("Terrain 2", "Terrain 3")
  end

  it "exclut un terrain fermé à cette date" do
    TerrainClosure.create!(terrain: "Terrain 2", starts_on: start_at.to_date, ends_on: start_at.to_date)
    expect(described_class.call(slot: slot)).not_to include("Terrain 2")
  end
end
