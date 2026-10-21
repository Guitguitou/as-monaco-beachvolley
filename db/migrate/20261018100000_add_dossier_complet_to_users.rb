# frozen_string_literal: true

class AddDossierCompletToUsers < ActiveRecord::Migration[8.0]
  # Les joueurs dont la licence est déjà payée gardent le droit de réserver :
  # on considère leur dossier complet pour ne bloquer personne en cours de saison.
  def up
    add_column :users, :dossier_complet, :boolean, null: false, default: false
    execute "UPDATE users SET dossier_complet = TRUE WHERE activated_at IS NOT NULL"
  end

  def down
    remove_column :users, :dossier_complet
  end
end
