# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataTable::State do
  def state(params) = described_class.new(ActionController::Parameters.new(params))

  it "garde la recherche, les filtres et le tri, et revient en page 1 quand ils changent" do
    current = state(q: " dupont ", f: { license_type: "libre" }, sort: "name", direction: "desc", page: "3")

    expect(current.to_params).to eq(q: "dupont", sort: "name", direction: "desc", f: { "license_type" => "libre" })
    expect(current.to_params(page: 2)).to include(page: 2)
  end

  it "inverse le sens sur la colonne déjà triée, et trie en ascendant sinon" do
    expect(state(sort: "name").sort_params(:name)).to include(sort: "name", direction: "desc")
    expect(state(sort: "name", direction: "desc").sort_params(:email)).to include(sort: "email", direction: "asc")
  end

  it "sait si un filtre est actif" do
    expect(state({}).filtered?).to be(false)
    expect(state(f: { email: "" }).filtered?).to be(false)
    expect(state(quick: "staff").filtered?).to be(true)
    expect(state(f: "n'importe quoi").filters).to eq({})
  end
end
