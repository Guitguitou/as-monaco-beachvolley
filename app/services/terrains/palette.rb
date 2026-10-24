# frozen_string_literal: true

module Terrains
  # Palette fermée des couleurs de terrain : pas de sélecteur libre, chaque
  # couleur reste lisible dans le calendrier (bordure, étiquette « T1 »).
  # Les teintes sont définies une seule fois dans application.css
  # (`--color-terrain-<clé>`) ; les classes ci-dessous sont écrites en entier
  # pour que Tailwind les détecte dans le code Ruby.
  class Palette
    Color = Data.define(:key, :label, :swatch_class, :text_class)

    COLORS = [
      Color.new("ocean", "Bleu océan", "bg-terrain-ocean", "text-white"),
      Color.new("ink", "Noir", "bg-terrain-ink", "text-white"),
      Color.new("gold", "Or", "bg-terrain-gold", "text-ink"),
      Color.new("green", "Vert", "bg-terrain-green", "text-white"),
      Color.new("purple", "Violet", "bg-terrain-purple", "text-white"),
      Color.new("orange", "Orange", "bg-terrain-orange", "text-white"),
      Color.new("teal", "Turquoise", "bg-terrain-teal", "text-white"),
      Color.new("pink", "Rose", "bg-terrain-pink", "text-white")
    ].freeze

    KEYS = COLORS.map(&:key).freeze

    def self.fetch(key)
      COLORS.find { |color| color.key == key }
    end

    # Première couleur pas encore prise par un terrain (la première sinon).
    def self.first_unused(used_keys)
      (KEYS - used_keys).first || KEYS.first
    end
  end
end
