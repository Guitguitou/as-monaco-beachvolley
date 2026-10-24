# frozen_string_literal: true

# Confirme les parties de jeu libre prêtes que leur créateur a laissées en
# suspens (voir Annonces::AutoConfirmation).
class AutoConfirmAnnoncesJob < ApplicationJob
  queue_as :default

  def perform
    Annonces::AutoConfirmation.call
  end
end
