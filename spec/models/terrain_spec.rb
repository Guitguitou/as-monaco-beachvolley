# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terrain, type: :model do
  describe "validations" do
    it "exige un nom unique" do
      create(:terrain, name: "Court central")

      expect(build(:terrain, name: "Court central")).not_to be_valid
      expect(build(:terrain, name: nil)).not_to be_valid
    end
  end

  describe ".resolve" do
    let!(:terrain) { create(:terrain, name: "Terrain 2") }

    it "trouve un terrain par id ou par son ancien nom" do
      expect(described_class.resolve(terrain.id.to_s)).to eq(terrain)
      expect(described_class.resolve(terrain.id)).to eq(terrain)
      expect(described_class.resolve("Terrain 2")).to eq(terrain)
    end

    it "ne trouve rien pour une valeur vide ou inconnue" do
      expect(described_class.resolve("")).to be_nil
      expect(described_class.resolve("Terrain 99")).to be_nil
      expect(described_class.resolve("0")).to be_nil
    end
  end

  describe "archivage" do
    let(:terrain) { create(:terrain) }

    it "retire le terrain archivé des terrains actifs" do
      other = create(:terrain)
      terrain.archive!

      expect(terrain).to be_archived
      expect(described_class.active).to contain_exactly(other)
    end

    it "garde le terrain archivé sur les sessions passées" do
      session = create(:session, terrain: terrain)
      terrain.archive!

      expect(session.reload.terrain.name).to eq(terrain.name)
    end

    it "supprime un terrain sans historique" do
      terrain

      expect { terrain.destroy }.to change(described_class, :count).by(-1)
    end

    it "refuse de supprimer un terrain qui a des sessions" do
      create(:session, terrain: terrain)

      expect(terrain.destroy).to be(false)
      expect(terrain.errors[:base].join).to include("archivez-le")
    end

    it "refuse de supprimer un terrain qui a des fermetures" do
      create(:terrain_closure, terrain: terrain)

      expect(terrain.destroy).to be(false)
    end

    it "refuse de supprimer un terrain occupé par un tournoi" do
      create(:tournament, terrain_ids: [ terrain.id ])

      expect(terrain.destroy).to be(false)
    end
  end

  describe "#color_slot" do
    it "répète les trois couleurs par position" do
      expect([ 1, 2, 3, 4 ].map { |position| build(:terrain, position: position).color_slot }).to eq([ 1, 2, 3, 1 ])
    end
  end
end
