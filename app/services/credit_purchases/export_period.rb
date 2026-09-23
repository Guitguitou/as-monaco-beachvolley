# frozen_string_literal: true

module CreditPurchases
  # Période d'export des achats saisie par l'admin : deux dates lisibles, dans
  # l'ordre, couvertes en journées entières.
  class ExportPeriod
    def initialize(start_param, end_param)
      @start_date = parse(start_param)
      @end_date = parse(end_param)
    end

    def error
      return "Veuillez sélectionner une période valide" if @start_date.nil? || @end_date.nil?

      "La date de début doit être antérieure à la date de fin" if @start_date > @end_date
    end

    def range
      @start_date.beginning_of_day..@end_date.end_of_day
    end

    def filename(extension)
      "achats_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.#{extension}"
    end

    private

    def parse(value)
      Date.parse(value) if value.present?
    rescue ArgumentError
      nil
    end
  end
end
