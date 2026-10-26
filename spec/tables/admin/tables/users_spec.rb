# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Tables::Users do
  let(:male_level) { create(:level, gender: "male") }
  let!(:zoe) do
    create(:user, first_name: "Zoé", last_name: "Arnaud", email: "zoe@example.com", license_type: "competition",
                  activated_at: 1.day.ago, dossier_complet: true)
  end
  let!(:marc) { create(:user, first_name: "Marc", last_name: "Blanc", email: "marc@club.fr", license_type: "libre", level: male_level,
                                  activated_at: nil, dossier_complet: false) }

  def filter(params)
    DataTable::Query.call(relation: User.all, definition: described_class.new,
                          state: DataTable::State.new(ActionController::Parameters.new(params))).to_a
  end

  it "cherche dans le nom et l'email" do
    expect(filter(q: " club ")).to eq([ marc ])
    expect(filter(q: "arnaud")).to eq([ zoe ])
  end

  it "filtre par colonne" do
    expect(filter(f: { license_type: "competition" })).to eq([ zoe ])
    expect(filter(f: { activated: "0" })).to eq([ marc ])
    expect(filter(f: { dossier_complet: "1" })).to eq([ zoe ])
    expect(filter(f: { levels: [ male_level.id.to_s ] })).to eq([ marc ])
    expect(filter(f: { email: "EXAMPLE" })).to eq([ zoe ])
  end

  it "propose le filtre rapide « Ne peut pas réserver »" do
    expect(filter(quick: "cannot_book")).to eq([ marc ])
  end

  it "trie par nom par défaut, et par une colonne triable sinon" do
    expect(filter({})).to eq([ zoe, marc ])
    expect(filter(sort: "email", direction: "desc")).to eq([ zoe, marc ])
    expect(filter(sort: "email")).to eq([ marc, zoe ])
    expect(filter(sort: "password", direction: "desc")).to eq([ zoe, marc ])
  end

  it "exporte les colonnes déclarées en CSV" do
    csv = DataTable::CsvExport.new(definition: described_class.new, records: [ zoe ]).call

    expect(csv.lines.first).to eq("Nom;Email;Rôles;Licence;Licence payée;Dossier complet;Groupe\n")
    expect(csv.lines.last).to start_with("Arnaud Zoé;zoe@example.com;;Compétition;Oui;Oui;")
  end
end
