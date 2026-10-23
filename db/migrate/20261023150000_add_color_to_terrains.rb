# frozen_string_literal: true

# Couleur choisie par l'admin dans Terrains::Palette, à la place de la couleur
# déduite de la position. Le backfill reproduit exactement le rendu actuel :
# position 1 → ocean, 2 → ink, 3 → gold, puis le cycle recommence.
class AddColorToTerrains < ActiveRecord::Migration[8.0]
  def up
    add_column :terrains, :color, :string
    execute <<~SQL
      UPDATE terrains SET color = CASE MOD(position - 1, 3)
        WHEN 0 THEN 'ocean'
        WHEN 1 THEN 'ink'
        ELSE 'gold'
      END
    SQL
    change_column_null :terrains, :color, false
  end

  def down
    remove_column :terrains, :color
  end
end
