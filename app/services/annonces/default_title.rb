# frozen_string_literal: true

module Annonces
  # Titre déduit du premier créneau d'une partie : « Jeu libre · sam 4 oct, soir ».
  # Le joueur qui veut juste jouer n'a pas à trouver un nom à sa partie.
  class DefaultTitle
    def self.for(annonce)
      first = annonce.slots.reject(&:marked_for_destruction?).map(&:start_at).compact.min
      return "Jeu libre" unless first

      "Jeu libre · #{I18n.l(first.to_date, format: :short_day)}, #{moment(first)}"
    end

    def self.moment(time)
      return "matin" if time.hour < 12
      return "après-midi" if time.hour < 18

      "soir"
    end
    private_class_method :moment
  end
end
