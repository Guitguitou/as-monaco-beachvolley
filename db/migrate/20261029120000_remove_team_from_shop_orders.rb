# frozen_string_literal: true

# L'équipe saisie à la main venait des bons de la salle : côté beach, la
# remise se fait par groupe d'entraînement, repris des niveaux du joueur.
class RemoveTeamFromShopOrders < ActiveRecord::Migration[8.1]
  def change
    remove_column :shop_orders, :team, :string
  end
end
