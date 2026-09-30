# frozen_string_literal: true

module Annonces
  # Créneaux déjà pris d'un joueur (sessions où il est inscrit en liste
  # principale). Même formule d'overlap que Registrations::ScheduleConflictQuery.
  class PlayerAgenda
    def initialize(user:)
      @user = user
    end

    def free_for?(slot)
      busy_ranges.none? { |busy_start, busy_end| slot.overlaps?(busy_start, busy_end) }
    end

    private

    attr_reader :user

    def busy_ranges
      @busy_ranges ||= user.sessions_registered.pluck(:start_at, :end_at)
    end
  end
end
