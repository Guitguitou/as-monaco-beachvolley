# frozen_string_literal: true

module Registrations
  # Désinscrit un joueur : rembourse s'il est encore temps, trace une
  # désinscription tardive sinon, puis rend la place à la liste d'attente.
  # Renvoie le message à afficher au joueur.
  class Cancellation
    def initialize(registration)
      @registration = registration
      @session = registration.session
      @amount = registration.required_credits_for(registration.user)
    end

    def call
      ActiveRecord::Base.transaction do
        @registration.destroy!
        TransactionService.new(@registration.user, @session, @amount).refund_transaction if refundable?
        LateCancellation.create!(user: @registration.user, session: @session) if paid? && past_deadline?
        @session.promote_from_waitlist!
      end
      # Le joueur a libéré un entraînement : ses autres inscriptions de la même
      # semaine peuvent redevenir prioritaires. Hors transaction, les promotions
      # notifient les joueurs.
      Sessions::WeeklyCascadeService.call(user: @registration.user, session: @session)
      message
    end

    private

    def paid?
      @amount.positive?
    end

    def refundable?
      paid? && !started? && !past_deadline?
    end

    # Une session déjà commencée n'est jamais remboursée, quel que soit son type.
    def started?
      Time.current > @session.start_at
    end

    # Pour les entraînements, le délai d'annulation coupe aussi le remboursement.
    def past_deadline?
      @session.entrainement? && @session.cancellation_deadline_at.present? &&
        Time.current > @session.cancellation_deadline_at
    end

    def message
      if paid? && started?
        "Désinscription réussie, mais la session a déjà eu lieu — pas de remboursement."
      elsif paid? && past_deadline?
        "Désinscription réussie, mais délai dépassé — pas de remboursement."
      else
        "Désinscription réussie ✅"
      end
    end
  end
end
