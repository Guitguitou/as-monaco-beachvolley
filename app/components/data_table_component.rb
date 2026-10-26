# frozen_string_literal: true

# Tableau de données filtrable de l'admin : recherche, filtres par colonne,
# filtres rapides, tri par en-tête, pagination et export CSV. Tout l'état vit
# dans l'URL (cf. DataTable::State) ; le tableau se recharge dans son Turbo
# Frame à chaque changement.
#
#   <%= render DataTableComponent.new(definition: @table, state: @state, pagination: @page,
#                                     url: admin_users_path, export_url: admin_users_path(format: :csv)) do |table| %>
#     <% @page.records.each do |user| %>
#       <% table.with_row do |row| %>
#         <% row.with_cell { user.full_name } %>
#       <% end %>
#     <% end %>
#   <% end %>
#
# Les lignes reprennent TableComponent::Row, une cellule par colonne de la
# définition, dans le même ordre. La première colonne reste figée lors du
# défilement horizontal.
class DataTableComponent < ApplicationComponent
  renders_many :rows, "TableComponent::Row"

  INPUT = "w-full min-w-24 rounded-none border-gray-300 py-1 text-xs font-normal normal-case tracking-normal " \
          "focus:border-brand focus:ring-brand"

  def initialize(definition:, state:, pagination:, url:, export_url: nil, empty_message: "Aucun résultat.")
    @definition = definition
    @state = state
    @pagination = pagination
    @url = url
    @export_url = export_url
    @empty_message = empty_message
  end

  delegate :turbo_frame_tag, :search_field_tag, :hidden_field_tag, to: :helpers

  private

  attr_reader :definition, :state, :pagination, :empty_message, :export_url

  def frame_id = "data_table_#{definition.class.name.demodulize.underscore}"

  def columns = definition.columns

  def url_with(params) = "#{@url}?#{params.to_query}".delete_suffix("?")

  def export_link = export_url && "#{export_url}#{'?' if state.to_params.any?}#{state.to_params.to_query}"

  def page_url(page) = url_with(state.to_params(page: page))

  def sort_url(column) = url_with(state.sort_params(column.key))

  def quick_url(quick) = url_with(state.to_params(quick: (quick.key.to_s unless state.quick == quick.key.to_s)))

  def reset_url = @url

  def sort_icon(column)
    return "chevrons-up-down" unless state.sorted_by?(column.key)

    state.direction == :asc ? "chevron-up" : "chevron-down"
  end

  def quick_classes(quick)
    active = state.quick == quick.key.to_s
    base = "inline-flex items-center gap-1 px-3 py-1 text-xs font-medium border rounded-none transition-colors"
    "#{base} #{active ? 'border-brand bg-brand text-white' : 'border-gray-300 bg-white text-gray-700 hover:border-brand'}"
  end

  def filter_input(column) = render(DataTable::FilterInputComponent.new(column: column, value: state.filter(column.key)))

  # Première colonne figée au défilement horizontal (tableaux larges sur mobile).
  def table_classes
    "min-w-full divide-y divide-gray-200 [&_tr>*:first-child]:sticky [&_tr>*:first-child]:left-0 " \
      "[&_tr>*:first-child]:z-10 [&_tbody_td:first-child]:bg-white [&_thead_th:first-child]:bg-gray-50"
  end
end
