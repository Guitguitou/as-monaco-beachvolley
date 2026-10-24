# frozen_string_literal: true

# Les factories acceptent un terrain sous forme de nom (« Terrain 1 »), d'objet
# Terrain, ou nil. Le nom est résolu, ou créé à la volée : la base de test part
# de schema.rb, sans les terrains insérés par la migration.
module FactoryHelpers
  def self.resolve_terrain(value)
    case value
    when nil, Terrain
      value
    else
      Terrain.find_or_create_by!(name: value.to_s) do |terrain|
        terrain.position = value.to_s[/\d+\z/]&.to_i || (Terrain.maximum(:position).to_i + 1)
        # Même couleur que le backfill de production pour « Terrain 1..3 ».
        terrain.color = Terrains::Palette::KEYS[(terrain.position - 1) % 3]
      end
    end
  end

  def self.terrain_ids(*names)
    names.map { |name| resolve_terrain(name).id }
  end
end
