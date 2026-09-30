# frozen_string_literal: true

# Sélecteur à options exclusives (Semaine / Mois, Hommes / Femmes…), piloté par
# le contrôleur Stimulus `switch` : chaque option affiche le panneau de même clé.
#
#   <div data-controller="switch">
#     <%= render SegmentedControlComponent.new(options: [
#       { key: "week", label: "Semaine" }, { key: "month", label: "Mois" }
#     ], label: "Période") %>
#     <div data-switch-target="panel" data-key="week">…</div>
#     <div data-switch-target="panel" data-key="month" hidden>…</div>
#   </div>
#
# La première option est sélectionnée par défaut, côté serveur, pour que la
# page s'affiche correctement avant le chargement du JavaScript.
class SegmentedControlComponent < ApplicationComponent
  def initialize(options:, label:, full_width: false)
    @options = options.map(&:symbolize_keys)
    @label = label
    @full_width = full_width
  end

  def call
    tag.div(role: "tablist", aria: { label: label }, class: container_classes) do
      safe_join(options.each_with_index.map { |option, index| option_tag(option, index.zero?) })
    end
  end

  private

  attr_reader :options, :label, :full_width

  def container_classes
    "#{full_width ? 'flex w-full' : 'inline-flex'} border border-gray-200 bg-gray-100 p-0.5"
  end

  def option_tag(option, selected)
    tag.button(type: "button", role: "tab", class: option_classes,
               aria: { selected: selected },
               data: { switch_target: "option", key: option[:key], action: "switch#select" }) do
      safe_join([ (lucide_icon(option[:icon], class: "w-3.5 h-3.5", aria: { hidden: true }) if option[:icon]), option[:label] ].compact)
    end
  end

  def option_classes
    "#{full_width ? 'flex-1' : ''} inline-flex items-center justify-center gap-1.5 rounded-none px-3 py-1.5 " \
      "text-xs font-bold uppercase tracking-wide text-gray-500 transition-colors hover:text-gray-900 " \
      "aria-selected:bg-white aria-selected:text-gray-900 aria-selected:shadow-sm"
  end
end
