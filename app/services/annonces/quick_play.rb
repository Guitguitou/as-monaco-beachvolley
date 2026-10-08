# frozen_string_literal: true

module Annonces
  # « Je veux jouer [samedi matin] » : si une partie ouverte au joueur existe
  # déjà sur ce moment, il la rejoint ; sinon on en crée une à son nom, à son
  # niveau, où il est d'office disponible, et les joueurs éligibles sont prévenus.
  #
  #   result = Annonces::QuickPlay.new(user:, quick_slot:).call
  #   result.annonce  # la partie rejointe ou créée
  #   result.joined   # true si le joueur a rejoint une partie existante
  class QuickPlay
    Result = Struct.new(:annonce, :joined, keyword_init: true)

    def initialize(user:, quick_slot:)
      @user = user
      @quick_slot = quick_slot
    end

    def call
      slot = matching_slot
      return join(slot) if slot

      Result.new(annonce: create_annonce, joined: false)
    end

    private

    attr_reader :user, :quick_slot

    def matching_slot
      OpenSlotsQuery.call(user: user).find { |slot| slot.overlaps?(quick_slot.start_at, quick_slot.end_at) }
    end

    def join(slot)
      unless slot.availabilities.any? { |availability| availability.user_id == user.id }
        AvailabilityToggle.new(annonce: slot.annonce, slot: slot, user: user).call
      end
      Result.new(annonce: slot.annonce, joined: true)
    end

    def create_annonce
      annonce = Annonce.transaction do
        Annonce.create!(user: user, levels: user.levels,
                        slots: [ AnnonceSlot.new(start_at: quick_slot.start_at, end_at: quick_slot.end_at) ])
               .tap { |created| AnnonceAvailability.create!(annonce_slot: created.slots.first, user: user) }
      end
      Notifier.new(annonce: annonce).notify_eligible_players
      annonce
    end
  end
end
