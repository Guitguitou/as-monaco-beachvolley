# frozen_string_literal: true

module Tournaments
  # Supprime un tournoi et ses sessions. Le pack est retiré de la boutique mais
  # conservé s'il a des achats, pour l'historique financier.
  class Destroy
    def initialize(tournament:)
      @tournament = tournament
    end

    def call
      ActiveRecord::Base.transaction do
        @tournament.sessions.destroy_all
        pack = @tournament.pack
        if pack&.credit_purchases&.exists?
          pack.update!(tournament_id: nil, active: false)
        else
          pack&.destroy!
        end
        @tournament.destroy!
      end
    end
  end
end
