# frozen_string_literal: true

# Tableau de données standard (admin, bilans coach).
#
# Le même markup — conteneur défilant, en-têtes gris en petites capitales,
# cellules px-6 py-4, ligne vide centrée avec icône — était recopié dans une
# quinzaine de vues.
#
#   <%= render TableComponent.new do |table| %>
#     <% table.with_column("Mois") %>
#     <% table.with_column("Total") %>
#     <% months.each do |month| %>
#       <% table.with_row do |row| %>
#         <% row.with_cell(weight: :medium) { month.name } %>
#         <% row.with_cell(weight: :semibold) { month.total } %>
#       <% end %>
#     <% end %>
#     <% table.with_empty(icon: "calendar-x", message: "Aucun mois") %>
#   <% end %>
#
# `framed: true` ajoute la bordure et l'ombre d'un tableau posé seul sur la
# page ; sans cadre, il s'insère dans une CardComponent.
# La ligne vide n'est rendue que s'il n'y a aucune ligne.
class TableComponent < ApplicationComponent
  renders_many :columns, ->(label, align: :left) do
    tag.th(label, scope: "col", class: "px-6 py-3 text-#{align} text-xs font-medium text-gray-500 uppercase tracking-wider")
  end
  renders_many :rows, "TableComponent::Row"
  renders_one :empty, ->(icon:, message:) do
    tag.tr do
      tag.td(colspan: columns.size, class: "px-6 py-8 text-center text-gray-500") do
        tag.div(class: "flex flex-col items-center gap-2") do
          safe_join([ lucide_icon(icon, class: "w-8 h-8 text-gray-300", aria: { hidden: true }), tag.span(message) ])
        end
      end
    end
  end

  def initialize(framed: false)
    @framed = framed
  end

  private

  def wrapper_classes
    @framed ? "overflow-x-auto rounded-none border border-gray-200 shadow-sm" : "overflow-x-auto"
  end

  # Une ligne : ses cellules, et ses attributs HTML (id, data-*) tels quels.
  class Row < ApplicationComponent
    renders_many :cells, "TableComponent::Cell"

    def initialize(**html_options)
      @html_options = html_options
    end

    def call
      tag.tr(**@html_options.merge(class: [ "hover:bg-gray-50", @html_options[:class] ].compact.join(" "))) do
        safe_join(cells)
      end
    end
  end

  # Une cellule : `wrap: true` pour un contenu sur plusieurs lignes.
  class Cell < ApplicationComponent
    WEIGHTS = { normal: "", medium: "font-medium", semibold: "font-semibold" }.freeze

    def initialize(weight: :normal, wrap: false, align: :left)
      @weight = weight
      @wrap = wrap
      @align = align
    end

    def call
      tag.td(content, class: classes)
    end

    private

    def classes
      [ "px-6 py-4 text-sm text-gray-900", ("whitespace-nowrap" unless @wrap),
        ("text-#{@align}" unless @align == :left), WEIGHTS.fetch(@weight) ].compact_blank.join(" ")
    end
  end
end
