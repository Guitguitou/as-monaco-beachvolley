require 'rails_helper'

RSpec.describe Annonces::AvailableTerrainsForSlotQuery do
  let(:start_at) { (Time.current + 2.days).change(hour: 19, min: 0) }
  let(:slot) { build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) }

  before { FactoryHelpers.terrain_ids("Terrain 1", "Terrain 2", "Terrain 3") }

  def available_names
    described_class.call(slot: slot).map(&:name)
  end

  it "retourne tous les terrains actifs quand aucun n'est occupé" do
    expect(available_names).to eq([ "Terrain 1", "Terrain 2", "Terrain 3" ])
  end

  it "ignore les terrains archivés" do
    Terrain.find_by!(name: "Terrain 3").archive!
    expect(available_names).to eq([ "Terrain 1", "Terrain 2" ])
  end

  it "exclut un terrain occupé par une session chevauchante" do
    create(:session, :jeu_libre, terrain: "Terrain 1", start_at: start_at, end_at: start_at + 2.hours)
    expect(available_names).to eq([ "Terrain 2", "Terrain 3" ])
  end

  it "exclut un terrain fermé à cette date" do
    TerrainClosure.create!(terrain: Terrain.find_by!(name: "Terrain 2"), starts_on: start_at.to_date, ends_on: start_at.to_date)
    expect(available_names).not_to include("Terrain 2")
  end
end
