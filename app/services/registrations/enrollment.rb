# frozen_string_literal: true

module Registrations
  # Inscrit un joueur à une session, en liste principale (débitée) ou en liste
  # d'attente, puis applique la priorité : un joueur prioritaire arrivé en
  # liste d'attente peut aussitôt déplacer un secondaire.
  #
  # `privileged` : un admin ou le coach de la session peut inscrire en coaching
  # privé et passer outre la deadline de 17h.
  class Enrollment
    Result = Data.define(:success?, :message)

    def initialize(user:, session:, waitlist:, privileged:)
      @session = session
      @registration = Registration.new(user: user, session: session, status: waitlist ? :waitlisted : :confirmed)
      @registration.allow_private_coaching_registration = true if privileged && session.coaching_prive?
      @registration.allow_deadline_bypass = true if privileged
    end

    def call
      ActiveRecord::Base.transaction do
        @registration.save!
        charge if @registration.confirmed?
        @session.rebalance!
      end
      Result.new(success?: true, message: @registration.reload.confirmed? ? "Inscription réussie ✅" : "Ajout en liste d'attente ✅")
    rescue StandardError => e
      Result.new(success?: false, message: (@registration.errors.full_messages.presence || [ e.message ]).to_sentence)
    end

    private

    def charge
      amount = @registration.required_credits_for(@registration.user)
      TransactionService.new(@registration.user, @session, amount).create_transaction if amount.positive?
    end
  end
end
