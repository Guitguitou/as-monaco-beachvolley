# frozen_string_literal: true

module Sessions
  # Semaine affichée par le calendrier des sessions : celle de la date passée
  # dans l'URL, ou la semaine en cours si elle manque ou est illisible.
  class CalendarWeek
    attr_reader :start_on

    def initialize(date_param)
      @start_on = parse(date_param).beginning_of_week(:monday)
    end

    def closures
      TerrainClosure.intersecting_range(start_on, start_on + 6.days).order(:terrain, :starts_on)
    end

    private

    def parse(date_param)
      date_param.present? ? Date.parse(date_param) : Time.zone.today
    rescue ArgumentError
      Time.zone.today
    end
  end
end
