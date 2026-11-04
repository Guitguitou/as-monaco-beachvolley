# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, "Compte actif" do
  let(:complet) { create(:user, activated_at: Time.current, dossier_complet: true) }
  let(:dossier_manquant) { create(:user, activated_at: Time.current, dossier_complet: false) }
  let(:licence_impayee) { create(:user, activated_at: nil, dossier_complet: true) }

  it "exige licence payée et dossier complet" do
    expect(complet.compte_actif?).to be(true)
    expect(dossier_manquant.compte_actif?).to be(false)
    expect(licence_impayee.compte_actif?).to be(false)
  end

  it "signale une licence payée en attente du dossier" do
    expect(dossier_manquant.dossier_en_attente?).to be(true)
    expect(complet.dossier_en_attente?).to be(false)
    expect(licence_impayee.dossier_en_attente?).to be(false)
  end

  it "filtre les comptes actifs" do
    expect(described_class.comptes_actifs).to contain_exactly(complet)
    dossier_manquant
    licence_impayee
    expect(described_class.comptes_actifs).to contain_exactly(complet)
  end
end
