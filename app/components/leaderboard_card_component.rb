# frozen_string_literal: true

# Carte d'une catégorie de classement (Records, Jeu libre…) : en-tête avec
# icône, sélecteur optionnel, puis le podium en contenu.
class LeaderboardCardComponent < ApplicationComponent
  renders_one :switcher

  ICON_TONES = {
    tournament: "bg-amber-50 text-amber-600",
    free_play: "bg-blue-50 text-blue-700",
    training: "bg-asmbv-red/10 text-asmbv-red",
    cold: "bg-sky-50 text-sky-500"
  }.freeze

  def initialize(category:, icon:, accent:)
    @category = category
    @icon = icon
    @accent = accent
  end

  private

  attr_reader :category, :icon, :accent

  def icon_classes
    "grid h-9 w-9 shrink-0 place-items-center rounded-lg #{ICON_TONES.fetch(accent)}"
  end
end
