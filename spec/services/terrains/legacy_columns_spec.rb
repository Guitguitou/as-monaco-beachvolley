# frozen_string_literal: true

require "rails_helper"

# L'ancien code (redéployable jusqu'à la migration « contract ») lit encore
# les colonnes `terrain` : elles doivent suivre terrain_id.
RSpec.describe Terrains::LegacyColumns do
  def legacy(record)
    record.class.connection.select_value("SELECT terrain FROM #{record.class.table_name} WHERE id = #{record.id}")
  end

  it "écrit la valeur d'enum d'une session, à la création comme à la mise à jour" do
    session = create(:session, terrain: create(:terrain, id: 2, name: "Terrain 2"))
    expect(legacy(session)).to eq(2)

    session.update!(terrain: create(:terrain, id: 3, name: "Terrain 3"))
    expect(legacy(session)).to eq(3)
  end

  it "laisse vide la colonne d'une session sur un terrain hors de l'ancien enum" do
    session = create(:session, terrain: create(:terrain, id: 4, name: "Terrain 4"))

    expect(legacy(session)).to be_nil
  end

  it "écrit le nom du terrain d'une fermeture" do
    closure = create(:terrain_closure, terrain: create(:terrain, name: "Terrain 2"))
    expect(legacy(closure)).to eq("Terrain 2")

    closure.update!(terrain: create(:terrain, name: "Court central"))
    expect(legacy(closure)).to eq("Court central")
  end

  it "garde les terrains d'un tournoi dans la colonne historique" do
    terrain_ids = FactoryHelpers.terrain_ids("Terrain 1", "Terrain 3")
    tournament = create(:tournament, terrain_ids: terrain_ids)

    expect(Tournament.connection.select_value("SELECT terrains FROM tournaments WHERE id = #{tournament.id}"))
      .to eq("{#{terrain_ids.join(",")}}")
  end
end
