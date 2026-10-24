# frozen_string_literal: true

# Passe en « expirée » les parties de jeu libre dont tous les créneaux sont
# passés : elles encombraient la liste et l'accueil sans pouvoir aboutir.
class ExpireAnnoncesJob < ApplicationJob
  queue_as :default

  def perform
    Annonce.open.without_upcoming_slot.update_all(status: Annonce.statuses[:expired], updated_at: Time.current)
  end
end
