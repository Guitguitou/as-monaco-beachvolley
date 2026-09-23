# frozen_string_literal: true

module PushNotifications
  # À qui envoyer la notification d'un événement, et vers quelle page elle
  # mène au clic.
  class EventRouting
    LOW_CREDITS = 10

    def initialize(event_type, context)
      @event_type = event_type
      @context = context
    end

    def users
      case @event_type
      when "session_created", "session_cancelled", "registration_opened", "stage_created", "stage_registration_opened"
        User.activated
      when "registration_confirmed", "registration_cancelled" then User.where(id: @context[:user]&.id)
      when "credit_low" then User.activated.joins(:balance).where("balances.amount < ?", LOW_CREDITS)
      else User.none
      end
    end

    def url
      case @event_type
      when "session_created", "session_cancelled", "registration_opened" then session_url_or(routes.sessions_path)
      when "registration_confirmed", "registration_cancelled" then session_url_or(routes.me_sessions_path)
      when "credit_low" then routes.packs_path
      when "stage_created", "stage_registration_opened" then @context[:stage] ? routes.stage_path(@context[:stage]) : routes.stages_path
      else routes.root_path
      end
    end

    private

    def session_url_or(fallback)
      @context[:session] ? routes.session_path(@context[:session]) : fallback
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
