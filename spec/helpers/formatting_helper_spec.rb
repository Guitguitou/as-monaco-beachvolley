require "rails_helper"

RSpec.describe FormattingHelper, type: :helper do
  describe "#human_duration" do
    it "affiche les heures et minutes" do
      expect(helper.human_duration(315)).to eq("5h15")
      expect(helper.human_duration(90)).to eq("1h30")
      expect(helper.human_duration(65)).to eq("1h05")
    end

    it "omet les minutes quand la durée est pile" do
      expect(helper.human_duration(120)).to eq("2h")
      expect(helper.human_duration(60)).to eq("1h")
    end

    it "reste en minutes sous l'heure" do
      expect(helper.human_duration(45)).to eq("45 min")
    end

    it "renvoie nil pour une durée nulle ou absente" do
      expect(helper.human_duration(0)).to be_nil
      expect(helper.human_duration(nil)).to be_nil
      expect(helper.human_duration(-10)).to be_nil
    end
  end

  describe "#session_duration" do
    it "calcule la durée entre deux horodatages" do
      start_at = Time.zone.parse("2026-08-28 16:30")
      expect(helper.session_duration(start_at, start_at + 315.minutes)).to eq("5h15")
    end

    it "renvoie nil si une borne manque" do
      expect(helper.session_duration(nil, Time.current)).to be_nil
      expect(helper.session_duration(Time.current, nil)).to be_nil
    end
  end

  describe "#credits_label" do
    it "dit « Gratuit » plutôt que « 0 crédits »" do
      expect(helper.credits_label(0)).to eq("Gratuit")
      expect(helper.credits_label(nil)).to eq("Gratuit")
    end

    it "accorde le singulier et le pluriel" do
      expect(helper.credits_label(1)).to eq("1 crédit")
      expect(helper.credits_label(3)).to eq("3 crédits")
    end
  end

  describe "#session_levels_label" do
    it "suffixe le genre uniquement pour distinguer les homonymes" do
      male = build_stubbed(:level, name: "G1", gender: "male")
      female = build_stubbed(:level, name: "G1", gender: "female")

      expect(helper.session_levels_label([ male, female ])).to eq("G1 M, G1 F")
    end

    it "laisse les noms intacts quand ils portent déjà le genre" do
      # Cas réel en production : les noms sont « G1 M », « G1 M bis »…
      # Suffixer systématiquement donnerait « G1 M M ».
      first = build_stubbed(:level, name: "G1 M", gender: "male")
      second = build_stubbed(:level, name: "G1 M bis", gender: "male")

      expect(helper.session_levels_label([ first, second ])).to eq("G1 M, G1 M bis")
    end

    it "dédoublonne les niveaux identiques" do
      male = build_stubbed(:level, name: "G1", gender: "male")
      same = build_stubbed(:level, name: "G1", gender: "male")

      expect(helper.session_levels_label([ male, same ])).to eq("G1")
    end

    it "renvoie nil sans niveau" do
      expect(helper.session_levels_label([])).to be_nil
      expect(helper.session_levels_label(nil)).to be_nil
    end
  end

  describe "#spots_left_label" do
    it "compte les places restantes" do
      expect(helper.spots_left_label(1, 4)).to eq("3 places")
      expect(helper.spots_left_label(3, 4)).to eq("1 place")
    end

    it "dit « Complet » quand il n'en reste plus" do
      expect(helper.spots_left_label(4, 4)).to eq("Complet")
      expect(helper.spots_left_label(6, 4)).to eq("Complet")
    end

    it "renvoie nil quand la session n'a pas de capacité" do
      expect(helper.spots_left_label(2, nil)).to be_nil
    end
  end
end
