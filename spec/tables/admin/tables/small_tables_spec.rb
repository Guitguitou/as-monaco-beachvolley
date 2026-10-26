# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tableaux simples de l'admin" do
  def filter(definition, relation, params)
    DataTable::Query.call(relation: relation, definition: definition,
                          state: DataTable::State.new(ActionController::Parameters.new(params))).to_a
  end

  it "filtre les stages à venir et par coach" do
    coach = create(:user, :coach)
    past = create(:stage, starts_on: 1.month.ago.to_date, ends_on: 1.month.ago.to_date + 2, main_coach: coach)
    future = create(:stage, starts_on: 1.month.from_now.to_date, ends_on: 1.month.from_now.to_date + 2)

    expect(filter(Admin::Tables::Stages.new, Stage.all, quick: "upcoming")).to eq([ future ])
    expect(filter(Admin::Tables::Stages.new, Stage.all, f: { coaches: coach.id.to_s })).to eq([ past ])
  end

  it "filtre les fermetures par terrain" do
    terrain = create(:terrain)
    closure = create(:terrain_closure, terrain: terrain)
    create(:terrain_closure)

    expect(filter(Admin::Tables::TerrainClosures.new, TerrainClosure.all, f: { terrain: terrain.id.to_s })).to eq([ closure ])
  end
end
