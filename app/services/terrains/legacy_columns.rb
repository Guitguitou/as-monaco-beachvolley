# frozen_string_literal: true

module Terrains
  # Écriture des anciennes colonnes `terrain` (avant le modèle Terrain), lues
  # par l'ancien code tant que la migration « contract » ne les a pas
  # supprimées. Session stockait la valeur d'enum (1..3, égale à l'id) ;
  # TerrainClosure, le nom. Un terrain au-delà de l'ancien enum n'a pas de
  # valeur d'enum : la colonne reste vide.
  module LegacyColumns
    LEGACY_ENUM_IDS = (1..3)

    def self.write_session(session)
      id = session.terrain_id
      session.write_attribute(:terrain, LEGACY_ENUM_IDS.cover?(id) ? id : nil)
    end

    def self.write_closure(closure)
      closure.write_attribute(:terrain, closure.terrain&.name)
    end
  end
end
