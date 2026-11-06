# frozen_string_literal: true

module Annonces
  # Données de la page « Jeu libre » : tout ce qui permet à un joueur de
  # trouver une partie, qu'elle soit lancée par un joueur ou par le club.
  class Board
    CLUB_SESSIONS_LIMIT = 6

    def initialize(user:)
      @user = user
    end

    # Créneaux des parties de joueurs, les plus près d'être complets d'abord.
    def open_slots
      @open_slots ||= OpenSlotsQuery.call(user: user)
    end

    # Sessions de jeu libre du club où il reste de la place.
    def club_sessions
      club_recommendations.sessions
    end

    delegate :card_state_for, to: :club_recommendations

    def quick_slots
      QuickSlot.available
    end

    def my_annonces
      @my_annonces ||= Annonce.where(user_id: user.id).ordered_by_recent
                              .includes(:levels, :user, slots: :availabilities)
    end

    private

    attr_reader :user

    def club_recommendations
      @club_recommendations ||= Sessions::Recommendations.new(user: user, types: "jeu_libre", limit: CLUB_SESSIONS_LIMIT)
    end
  end
end
