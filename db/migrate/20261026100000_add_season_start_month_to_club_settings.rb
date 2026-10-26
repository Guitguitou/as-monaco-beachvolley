# frozen_string_literal: true

# Mois de début de la Saison (cf. GLOSSARY.md) : septembre par défaut.
class AddSeasonStartMonthToClubSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :club_settings, :season_start_month, :integer, default: 9, null: false
  end
end
