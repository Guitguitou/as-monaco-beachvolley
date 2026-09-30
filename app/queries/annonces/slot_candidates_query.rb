# frozen_string_literal: true

module Annonces
  # Joueurs à prévenir pour un créneau de jeu libre : activés, d'un niveau
  # compatible avec la partie, pas encore dispos sur ce créneau et sans
  # session qui le chevauche. Le créateur n'est jamais prévenu de sa partie.
  class SlotCandidatesQuery
    def self.call(slot:)
      new(slot: slot).call
    end

    def initialize(slot:)
      @slot = slot
      @annonce = slot.annonce
    end

    def call
      level_matched(User.activated)
        .where.not(id: annonce.user_id)
        .where.not(id: AnnonceAvailability.where(annonce_slot_id: slot.id).select(:user_id))
        .where.not(id: busy_user_ids)
    end

    private

    attr_reader :slot, :annonce

    def level_matched(users)
      level_ids = annonce.levels.map(&:id)
      return users if level_ids.empty?

      users.where(id: UserLevel.where(level_id: level_ids).select(:user_id))
    end

    def busy_user_ids
      Registration.confirmed
                  .joins(:session)
                  .where("sessions.start_at < ? AND sessions.end_at > ?", slot.end_at, slot.start_at)
                  .select(:user_id)
    end
  end
end
