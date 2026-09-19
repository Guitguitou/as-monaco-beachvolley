# frozen_string_literal: true

module Sherlock
  # Applique l'issue d'un paiement à un achat.
  #
  # Le retour navigateur et le webhook serveur à serveur passent tous les deux
  # ici et peuvent arriver dans n'importe quel ordre, voire un seul des deux :
  # l'opération est donc idempotente, et un achat déjà payé ne redescend jamais
  # (une notification de refus en retard ne doit pas effacer un encaissement).
  class ApplyOutcome
    def self.call(...)
      new(...).call
    end

    def initialize(purchase:, fields:)
      @purchase = purchase
      @fields = fields
      @outcome = Outcome.new(fields)
    end

    def call
      trace_response

      case outcome.to_sym
      when :paid then mark_paid
      when :cancelled then mark_cancelled
      else mark_failed
      end

      outcome.to_sym
    end

    private

    attr_reader :purchase, :fields, :outcome

    def trace_response
      purchase.update!(
        sherlock_fields: purchase.sherlock_fields.merge(
          "callback" => fields.to_h,
          "received_at" => Time.current.iso8601
        )
      )
    end

    def mark_paid
      return if purchase.paid_status?

      purchase.credit!
      PostPaymentFulfillmentJob.perform_later(purchase.id)
    end

    def mark_cancelled
      return if purchase.paid_status?

      purchase.update!(status: :cancelled)
    end

    def mark_failed
      return if purchase.paid_status?

      purchase.mark_as_failed!(reason: outcome.reason)
    end
  end
end
