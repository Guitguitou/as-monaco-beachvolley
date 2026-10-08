# frozen_string_literal: true

# Liste réordonnable par glisser-déposer (souris et tactile). Chaque élément se
# déplace par sa poignée ; au lâcher, le nouvel ordre est envoyé en PATCH à
# `url` sous forme de `param[]` (les `id` des éléments, dans l'ordre).
#
#   <%= render SortableComponent.new(url: reorder_path, class_name: "grid grid-cols-4 gap-4") do |list| %>
#     <% records.each do |record| %>
#       <% list.with_item(id: record.id) do %>
#         <%= render SortableComponent::Handle.new %> …
#       <% end %>
#     <% end %>
#   <% end %>
class SortableComponent < ApplicationComponent
  renders_many :items, ->(id:, class_name: nil, &block) do
    content_tag(:li, view_context.capture(&block),
                class: [ "relative", class_name ].compact.join(" "),
                data: { sortable_target: "item", sortable_id: id })
  end

  def initialize(url:, param: "ids", class_name: nil)
    @url = url
    @param = param
    @class_name = class_name
  end

  def call
    content_tag(:ul, safe_join(items),
                class: @class_name,
                data: { controller: "sortable", sortable_url_value: @url, sortable_param_value: @param })
  end

  # Poignée à placer dans chaque élément.
  class Handle < ApplicationComponent
    def initialize(label: "Déplacer", class_name: nil)
      @label = label
      @class_name = class_name
    end

    def call
      tag.button(helpers.lucide_icon("grip-vertical", size: 16),
                 type: "button",
                 title: @label,
                 "aria-label": @label,
                 class: [ "cursor-grab active:cursor-grabbing touch-none rounded-none border border-gray-300 bg-white p-1.5 text-gray-600 hover:text-gray-900", @class_name ].compact.join(" "),
                 data: { sortable_target: "handle", action: "pointerdown->sortable#start" })
    end
  end
end
