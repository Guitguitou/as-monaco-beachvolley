# frozen_string_literal: true

# Cadrage de la photo de profil dans le cercle de l'avatar : point focal en
# pourcentage de l'image et facteur de zoom, appliqués en CSS au rendu.
class AddAvatarCropToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.float :avatar_crop_x, null: false, default: 50.0
      t.float :avatar_crop_y, null: false, default: 50.0
      t.float :avatar_zoom, null: false, default: 1.0
    end
  end
end
