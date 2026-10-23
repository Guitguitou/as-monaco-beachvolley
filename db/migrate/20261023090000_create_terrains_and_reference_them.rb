# frozen_string_literal: true

# Phase « expand » : les terrains deviennent une table. Les anciennes colonnes
# (sessions.terrain, terrain_closures.terrain) restent en place et intactes ;
# elles seront supprimées dans une migration ultérieure (« contract »), une
# fois le nouveau code stabilisé en production.
#
# Les ids 1..3 sont imposés pour coïncider avec les valeurs de l'ancien enum
# (sessions.terrain et tournaments.terrains), ce qui rend le backfill direct.
# tournaments.terrains garde son nom (exposé en terrain_ids côté modèle) : le
# renommage appartient à la migration « contract », pour que l'ancien code
# reste redéployable d'ici là.
class CreateTerrainsAndReferenceThem < ActiveRecord::Migration[8.0]
  def up
    create_table :terrains do |t|
      t.string :name, null: false
      t.integer :position, null: false
      t.datetime :archived_at
      t.timestamps
    end
    add_index :terrains, :name, unique: true

    execute <<~SQL
      INSERT INTO terrains (id, name, position, created_at, updated_at) VALUES
        (1, 'Terrain 1', 1, NOW(), NOW()),
        (2, 'Terrain 2', 2, NOW(), NOW()),
        (3, 'Terrain 3', 3, NOW(), NOW())
    SQL
    execute "SELECT setval(pg_get_serial_sequence('terrains', 'id'), (SELECT MAX(id) FROM terrains))"

    add_reference :sessions, :terrain, null: true, foreign_key: true, index: true
    add_reference :terrain_closures, :terrain, null: true, foreign_key: true, index: true

    execute "UPDATE sessions SET terrain_id = terrain WHERE terrain IS NOT NULL"
    execute <<~SQL
      UPDATE terrain_closures
      SET terrain_id = terrains.id
      FROM terrains
      WHERE terrains.name = terrain_closures.terrain
    SQL

    verify_backfill!
  end

  def down
    remove_reference :terrain_closures, :terrain, foreign_key: true, index: true
    remove_reference :sessions, :terrain, foreign_key: true, index: true
    drop_table :terrains
  end

  private

  # Toute ligne non rattachée annule la migration (et la transaction) : mieux
  # vaut un déploiement bloqué qu'une session sans terrain en production.
  def verify_backfill!
    orphan_sessions = select_value("SELECT COUNT(*) FROM sessions WHERE terrain IS NOT NULL AND terrain_id IS NULL").to_i
    orphan_closures = select_value("SELECT COUNT(*) FROM terrain_closures WHERE terrain_id IS NULL").to_i
    unknown_tournament_terrains = select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM tournaments
      WHERE EXISTS (SELECT 1 FROM unnest(terrains) AS t(id) WHERE t.id NOT IN (SELECT id FROM terrains))
    SQL
    return if orphan_sessions.zero? && orphan_closures.zero? && unknown_tournament_terrains.zero?

    raise "Backfill terrain incomplet : #{orphan_sessions} session(s), #{orphan_closures} fermeture(s), " \
          "#{unknown_tournament_terrains} tournoi(s) sans terrain valide"
  end
end
