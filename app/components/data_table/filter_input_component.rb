# frozen_string_literal: true

module DataTable
  # Champ de filtre d'une colonne, sous son en-tête : texte, liste, oui/non,
  # ou plage (de / à) de dates ou de nombres. Nommé f[clé] dans l'URL.
  class FilterInputComponent < ApplicationComponent
    INPUT = DataTableComponent::INPUT

    def initialize(column:, value:, form:)
      @column = column
      @filter = column.filter
      @value = value
      @form = form
    end

    def call
      case @filter.type
      when :text then text_field_tag(name, @value, class: INPUT, placeholder: "Filtrer…", aria: label, data: debounced, form: @form)
      when :select, :boolean then select
      when :date_range then range(:date_field)
      when :number_range then range(:number_field, step: "any")
      end
    end

    private

    def name(suffix = nil) = "f[#{@column.key}]#{suffix}"

    def label = { label: "Filtrer #{@column.label}" }

    def submit = { action: "change->auto-submit#submit" }

    def debounced = { action: "input->auto-submit#debouncedSubmit" }

    def select
      return checkboxes if @filter.respond_to?(:multiple?) && @filter.multiple?

      select_tag(name, options_for_select(@filter.options, @value), include_blank: "Tous", class: INPUT, aria: label,
                                                                    data: submit, form: @form)
    end

    # Choix multiple : une liste déroulante de cases à cocher, aussi compacte qu'un select.
    def checkboxes
      selected = Array(@value).map(&:to_s)
      tag.details(class: "relative") do
        safe_join([
          tag.summary(selected.any? ? "#{selected.size} choisi(s)" : "Tous", class: "#{INPUT} cursor-pointer list-none border bg-white px-2"),
          tag.div(class: "absolute z-20 mt-1 max-h-64 w-56 overflow-y-auto border border-gray-200 bg-white p-2 shadow-lg") do
            safe_join(@filter.options.map { |label, value| checkbox(label, value.to_s, selected.include?(value.to_s)) })
          end
        ])
      end
    end

    def checkbox(label, value, checked)
      tag.label(class: "flex items-center gap-2 py-1 text-xs font-normal normal-case text-gray-700") do
        safe_join([ check_box_tag(name("[]"), value, checked, id: nil, class: "rounded-none text-brand", data: submit, form: @form), label ])
      end
    end

    def range(field, **options)
      bounds = @value.is_a?(Hash) ? @value : {}
      tag.div(class: "flex flex-col gap-1") do
        safe_join(%w[from to].map do |bound|
          public_send(:"#{field}_tag", name("[#{bound}]"), bounds[bound], class: INPUT, data: submit, form: @form,
                      placeholder: bound == "from" ? "De" : "À", aria: { label: "#{@column.label} : #{bound == 'from' ? 'de' : 'à'}" }, **options)
        end)
      end
    end

    delegate :text_field_tag, :select_tag, :check_box_tag, :options_for_select, :date_field_tag, :number_field_tag, to: :helpers
  end
end
