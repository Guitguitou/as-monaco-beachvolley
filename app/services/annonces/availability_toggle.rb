# frozen_string_literal: true

module Annonces
  # Un joueur se déclare disponible sur un créneau d'annonce, ou retire sa
  # disponibilité. L'organisateur n'est prévenu que des nouvelles réponses.
  class AvailabilityToggle
    def initialize(annonce:, slot:, user:)
      @annonce = annonce
      @slot = slot
      @user = user
    end

    def call
      availability = AnnonceAvailability.find_by(annonce_slot: @slot, user: @user)
      return availability.destroy if availability

      AnnonceAvailability.create(annonce_slot: @slot, user: @user)
      CreationNotifier.new(annonce: @annonce).notify_creator_of_response(from: @user)
    end
  end
end
