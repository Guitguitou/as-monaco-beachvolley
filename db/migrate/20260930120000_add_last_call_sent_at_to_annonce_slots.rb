# Horodate l'envoi de la relance « plus qu'un joueur » d'un créneau de jeu
# libre, pour ne l'envoyer qu'une fois même si des joueurs vont et viennent.
class AddLastCallSentAtToAnnonceSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :annonce_slots, :last_call_sent_at, :datetime
  end
end
