# frozen_string_literal: true

module Annonces
  # Un joueur se déclare disponible sur un créneau à venir d'une partie, ou
  # retire sa disponibilité. Seules les nouvelles réponses notifient : le
  # créateur (réponse, ou quota atteint) et, quand il ne manque plus qu'un
  # joueur, les joueurs éligibles — une seule fois par créneau.
  class AvailabilityToggle
    def initialize(annonce:, slot:, user:)
      @annonce = annonce
      @slot = slot
      @user = user
    end

    def call
      return false unless slot.upcoming?

      availability = AnnonceAvailability.find_by(annonce_slot: slot, user: user)
      return availability.destroy if availability

      AnnonceAvailability.create!(annonce_slot: slot, user: user)
      notify_progress
    end

    private

    attr_reader :annonce, :slot, :user

    def notify_progress
      slot.availabilities.reset
      notifier = Notifier.new(annonce: annonce)

      if slot.availabilities.size == annonce.min_players && user != annonce.user
        notifier.notify_quota_reached(slot: slot)
      else
        notifier.notify_creator_of_response(from: user)
      end

      send_last_call(notifier) if slot.missing_players == 1 && slot.last_call_sent_at.nil?
      true
    end

    def send_last_call(notifier)
      slot.update!(last_call_sent_at: Time.current)
      notifier.notify_last_call(slot: slot)
    end
  end
end
