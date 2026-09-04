# frozen_string_literal: true

# En-tête de section : titre display, sous-titre optionnel, action à droite.
#
# Le triptyque titre Anton + sous-titre + lien « Tout voir » apparaît trois fois
# dans home/show et une fois par section du profil.
#
#   render SectionHeaderComponent.new(title: "Mes stats",
#                                     subtitle: "Depuis ton inscription") do |header|
#     header.with_action { link_to "Tout voir", path, class: "..." }
#   end
class SectionHeaderComponent < ApplicationComponent
  renders_one :action

  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  private

  attr_reader :title, :subtitle
end
