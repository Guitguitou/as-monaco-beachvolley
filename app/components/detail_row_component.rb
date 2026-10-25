# frozen_string_literal: true

# Ligne « icône + libellé … valeur » d'une fiche (stages, packs).
#
#   <%= render DetailRowComponent.new(icon: "calendar-days", label: "Dates") do %>
#     12/07 - 18/07
#   <% end %>
#
# Les lignes se séparent d'un filet ; `last: true` retire celui de la dernière.
class DetailRowComponent < ApplicationComponent
  def initialize(icon:, label:, last: false)
    @icon = icon
    @label = label
    @last = last
  end

  def call
    tag.div(class: row_classes) do
      safe_join([
        tag.div(class: "flex items-center gap-2 text-gray-600") do
          safe_join([ lucide_icon(@icon, size: 16, class: "text-gray-500", aria: { hidden: true }),
                      tag.span(@label, class: "text-sm font-medium") ])
        end,
        tag.span(content, class: "text-xs text-gray-500 text-right")
      ])
    end
  end

  private

  def row_classes
    base = "flex items-center justify-between gap-3"
    @last ? base : "#{base} mb-3 pb-3 border-b border-gray-100"
  end
end
