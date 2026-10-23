# frozen_string_literal: true

# Règles du club éditables par l'admin. Les valeurs par défaut sont celles de
# Monaco : la ligne existante (ou créée ensuite) garde le comportement actuel.
class AddClubRulesToClubSettings < ActiveRecord::Migration[8.0]
  def change
    change_table :club_settings, bulk: true do |t|
      t.integer :entrainement_price_cents, null: false, default: 400
      t.integer :jeu_libre_price_cents, null: false, default: 300
      t.integer :coaching_prive_price_cents, null: false, default: 1500
      t.integer :stage_price_cents, null: false, default: 0
      t.integer :priority_window_hours, null: false, default: 24
      t.integer :registration_deadline_hour, null: false, default: 17
      t.integer :registration_opening_days, null: false, default: 7
      t.string :cancellation_deadline_mode, null: false, default: "eve_at_hour"
      t.integer :cancellation_deadline_hour, null: false, default: 22
      t.integer :cancellation_hours_before, null: false, default: 24
    end

    reversible do |dir|
      dir.up { execute "INSERT INTO club_settings (created_at, updated_at) SELECT NOW(), NOW() WHERE NOT EXISTS (SELECT 1 FROM club_settings)" }
    end
  end
end
