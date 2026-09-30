# frozen_string_literal: true

module Annonces
  # Confirme d'office les parties prêtes que leur créateur n'a pas confirmées :
  # dès qu'un créneau ayant atteint le quota commence dans moins de 24 h, la
  # session est créée sur le créneau le plus rempli ayant un terrain libre.
  # Une partie prête ne doit pas tomber à l'eau parce que son créateur a oublié.
  class AutoConfirmation
    WINDOW = 24.hours

    def self.call(now: Time.current)
      new(now: now).call
    end

    def initialize(now:)
      @now = now
    end

    def call
      candidates.filter_map { |annonce| confirm(annonce) }
    end

    private

    attr_reader :now

    def candidates
      Annonce.open
             .where(id: AnnonceSlot.where(start_at: now..(now + WINDOW)).select(:annonce_id))
             .includes(:user, slots: { availabilities: :user })
    end

    def confirm(annonce)
      slot, terrain = slot_with_terrain(annonce)
      return unless slot

      result = ConfirmationService.new(annonce: annonce, slot: slot, terrain: terrain).call
      Notifier.new(annonce: annonce)
              .notify_confirmed(session: result.session, users: (result.registered + [ annonce.user ]).uniq)
      result
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[Jeu libre] confirmation auto impossible pour la partie #{annonce.id} : #{e.message}")
      nil
    end

    def slot_with_terrain(annonce)
      annonce.confirmable_slots
             .select { |slot| slot.start_at <= now + WINDOW }
             .sort_by { |slot| [ -slot.availabilities.size, slot.start_at ] }
             .each do |slot|
               terrain = AvailableTerrainsForSlotQuery.call(slot: slot).first
               return [ slot, terrain ] if terrain
             end
      nil
    end
  end
end
