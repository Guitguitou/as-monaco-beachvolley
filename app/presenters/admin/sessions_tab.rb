# frozen_string_literal: true

module Admin
  # Onglet Sessions du dashboard : les prochaines sessions, ou un type de
  # session sur une période (semaine, mois, année) avec sa navigation.
  class SessionsTab
    UPCOMING_LIMIT = 100

    attr_reader :sub_tab

    def initialize(params)
      @params = params
      @sub_tab = params[:session_type].to_s.presence || "upcoming"
    end

    def upcoming?
      sub_tab == "upcoming"
    end

    def upcoming_sessions
      Session.upcoming.includes(:registrations, :user).ordered_by_start.limit(UPCOMING_LIMIT)
    end

    def period
      @period ||= SessionsPeriod.new(@params[:period].presence, @params[:period_anchor])
    end

    def sessions_by_type
      scope = Session.where(start_at: period.range).includes(:registrations, :user)
      scope = scope.where(session_type: sub_tab) if Session.session_types.key?(sub_tab)
      scope.order(start_at: :desc)
    end

    def previous_period_params
      period_params(period.previous_anchor)
    end

    def next_period_params
      period_params(period.next_anchor)
    end

    private

    def period_params(anchor)
      { tab: "sessions", session_type: sub_tab, period: period.name, period_anchor: anchor }
    end
  end
end
