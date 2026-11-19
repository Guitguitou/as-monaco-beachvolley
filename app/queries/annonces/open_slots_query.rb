# frozen_string_literal: true

module Annonces
  # Créneaux de jeu libre à venir qu'un joueur peut rejoindre, ou qu'il a déjà
  # rejoints : ceux des parties des autres auxquelles il est éligible, et ceux
  # de ses propres parties. Les créneaux les plus près d'être complets passent
  # en tête — ce sont eux qui ont besoin de lui —, puis les plus proches.
  class OpenSlotsQuery
    def self.call(user:, limit: nil)
      new(user: user).call.then { |slots| limit ? slots.first(limit) : slots }
    end

    def initialize(user:)
      @user = user
      @agenda = PlayerAgenda.new(user: user)
    end

    def call
      annonces.flat_map(&:upcoming_slots)
              .select { |slot| joined?(slot) || agenda.free_for?(slot) }
              .sort_by { |slot| [ slot.missing_players, slot.start_at ] }
    end

    private

    attr_reader :user, :agenda

    def annonces
      EligibleAnnoncesQuery.call(user: user) + own_annonces
    end

    def own_annonces
      Annonce.open.where(user_id: user.id).includes(:user, slots: { availabilities: :user })
    end

    def joined?(slot)
      slot.availabilities.any? { |availability| availability.user_id == user.id }
    end
  end
end
