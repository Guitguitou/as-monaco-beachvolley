# frozen_string_literal: true

module Sessions
  # Nom, jour, horaire et terrain d'une session, tels qu'affichés sur les
  # cartes et les listes.
  class Schedule
    def initialize(session)
      @session = session
    end

    def title
      @session.title.presence || @session.display_name
    end

    def day_label
      I18n.l(@session.start_at.to_date, format: :day_and_month)
    end

    def time_range
      "#{I18n.l(@session.start_at, format: :time)} – #{I18n.l(@session.end_at, format: :time)}"
    end

    def terrain_label
      @session.terrain.to_s.split("_").last
    end
  end
end
