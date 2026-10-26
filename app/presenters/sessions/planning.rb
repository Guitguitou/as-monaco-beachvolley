# frozen_string_literal: true

module Sessions
  # Planning des sessions vu par un joueur : vue calendrier (événements,
  # fermetures, agenda mobile) ou vue grille des prochaines sessions.
  class Planning
    VIEWS = %w[grid calendar].freeze

    attr_reader :view, :for_me

    def initialize(user:, params:, url_for:)
      @user = user
      @params = params
      @url_for = url_for
      @view = params[:view].presence_in(VIEWS) || "calendar"
      @for_me = ActiveModel::Type::Boolean.new.cast(params[:for_me])
    end

    def calendar? = view == "calendar"

    def events = calendar.sessions

    def closures = calendar.closures

    def agenda
      MobileAgenda.new(events: events, user: @user, date_param: @params[:date])
    end

    def grid
      UpcomingGrid.new(user: @user, sessions: filter.apply(Session.held.upcoming.ordered_by_start))
    end

    private

    def calendar
      @calendar ||= CalendarEvents.new(
        user: @user, url_for: @url_for,
        sessions: filter.apply(Session.held.includes(:levels, :user, :terrain).order(start_at: :desc))
      )
    end

    def filter
      ListingFilter.new(terrain: @params[:terrain], for_me: for_me, level_ids: @user.levels.pluck(:id))
    end
  end
end
