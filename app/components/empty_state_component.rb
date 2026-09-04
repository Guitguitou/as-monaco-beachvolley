# frozen_string_literal: true

# État vide standard.
#
# Le repo en comptait trois dialectes concurrents : la carte centrée de
# home/show, le `border-dashed` des annonces, et le `text-gray-500 py-4` de
# l'admin. Celui-ci reprend le premier, le plus abouti.
#
#   render EmptyStateComponent.new(icon: "volleyball", title: "Rien de prévu",
#                                  description: "Tu n'es inscrit à aucune session.")
#
# Le slot `action` accueille le bouton de sortie éventuel.
class EmptyStateComponent < ApplicationComponent
  renders_one :action

  def initialize(icon:, title:, description: nil, compact: false)
    @icon = icon
    @title = title
    @description = description
    @compact = compact
  end

  private

  attr_reader :icon, :title, :description, :compact

  def wrapper_classes
    "text-center #{compact ? 'px-5 py-8' : 'border border-gray-200 bg-white rounded-xl p-6'}"
  end

  def icon_classes
    "mx-auto text-gray-300 #{compact ? 'w-8 h-8' : 'w-10 h-10'}"
  end
end
