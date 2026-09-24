# frozen_string_literal: true

module Registrations
  # Prévient le coach d'un entraînement quand un joueur rejoint la liste
  # principale le jour même (inscription directe ou promotion depuis la liste
  # d'attente) : la liste des présents a pu changer depuis sa dernière consultation.
  class SameDayCoachNotifier
    include Rails.application.routes.url_helpers

    def initialize(registration, promoted: false)
      @registration = registration
      @session = registration.session
      @promoted = promoted
    end

    def call
      return unless notifiable?

      SendPushNotificationJob.perform_later(
        @session.user_id,
        title: "Inscription de dernière minute 🏐",
        body: "#{@registration.user.full_name} #{action} #{@session.title} " \
              "aujourd'hui à #{I18n.l(@session.start_at, format: '%H:%M')}",
        url: session_path(@session)
      )
    end

    private

    def action
      @promoted ? "passe de la liste d'attente à la liste principale de" : "vient de s'inscrire à"
    end

    def notifiable?
      @session.entrainement? &&
        @registration.confirmed? &&
        @session.start_at.to_date == Date.current &&
        @registration.user_id != @session.user_id
    end
  end
end
