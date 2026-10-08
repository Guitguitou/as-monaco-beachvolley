# frozen_string_literal: true

# Section de la page d'accueil publique : étiquette rouge, titre display,
# chapeau optionnel, puis le contenu. Reprend la grammaire de la plaquette
# du club (étiquette + grand titre Anton) sur fond clair ou sombre.
#
#   render LandingSectionComponent.new(eyebrow: "Accès", title: "Venir à La Turbie",
#                                      tone: :dark) do
#     ...
#   end
class LandingSectionComponent < ApplicationComponent
  TONES = {
    light: "bg-white text-gray-900",
    muted: "bg-gray-50 text-gray-900",
    dark: "bg-gray-950 text-white"
  }.freeze

  def initialize(eyebrow:, title:, subtitle: nil, tone: :light, id: nil)
    @eyebrow = eyebrow
    @title = title
    @subtitle = subtitle
    @tone = tone
    @id = id
  end

  private

  attr_reader :eyebrow, :title, :subtitle, :tone, :id

  def dark?
    tone.to_sym == :dark
  end

  def section_classes
    "py-16 sm:py-20 #{TONES.fetch(tone.to_sym)}"
  end

  def subtitle_classes
    "mt-4 max-w-2xl text-base sm:text-lg #{dark? ? 'text-white/70' : 'text-gray-600'}"
  end
end
