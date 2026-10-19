# frozen_string_literal: true

module Sessions
  # Agenda du planning sur mobile : un bandeau des sept jours de la semaine
  # (avec un point par session), les prochaines sessions du joueur, et la
  # liste du jour choisi. Construit à partir des événements du calendrier
  # (Sessions::CalendarEvents#sessions) : statut et libellés sont les mêmes.
  class MobileAgenda
    Day = Data.define(:date, :statuses) do
      def today? = date == Time.zone.today
    end

    attr_reader :day

    def initialize(events:, user:, date_param:)
      @events = events
      @user = user
      @day = parse(date_param)
    end

    def week
      monday = day.beginning_of_week(:monday)
      (monday..(monday + 6.days)).map { |date| Day.new(date: date, statuses: events_on(date).pluck(:status)) }
    end

    def events_of_day
      events_on(day)
    end

    def previous_week = day - 7.days
    def next_week = day + 7.days

    # Sessions à venir où le joueur est inscrit ou en attente.
    def upcoming
      @upcoming ||= Registration.where(user: @user)
        .joins(:session).merge(Session.held).where(sessions: { start_at: Time.current.. })
        .includes(:session).order("sessions.start_at").limit(6).to_a
    end

    private

    def events_on(date)
      by_date[date] || []
    end

    def by_date
      @by_date ||= @events.group_by { |event| Time.zone.parse(event[:start]).to_date }
        .transform_values { |list| list.sort_by { |event| event[:start] } }
    end

    def parse(date_param)
      date_param.present? ? Date.parse(date_param) : Time.zone.today
    rescue ArgumentError
      Time.zone.today
    end
  end
end
