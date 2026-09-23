module CreditPurchases
  class ProcessPayment
    def self.call(purchase:)
      new(purchase: purchase).call
    end

    def initialize(purchase:)
      @purchase = purchase
    end

    def call
      return if purchase.paid_status?

      ActiveRecord::Base.transaction do
        processor_for(purchase).call
        purchase.update!(status: :paid, paid_at: Time.current)
      end
    end

    private

    attr_reader :purchase

    def processor_for(purchase)
      return Processors::Credits.new(purchase:) if purchase.credits_pack?
      return Processors::LogOnly.new(purchase:, label: "Stage") if purchase.stage_pack?
      return Processors::Licence.new(purchase:) if purchase.licence_pack?
      return Processors::LogOnly.new(purchase:, label: "Inscription tournoi") if purchase.inscription_tournoi_pack?
      return Processors::LogOnly.new(purchase:, label: "Equipements") if purchase.equipements_pack?

      raise "Type de pack non reconnu"
    end
  end
end
