module Sherlock
  class Gateway
    # Interface abstraite pour les gateways de paiement Sherlock
    
    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      raise NotImplementedError, "#{self.class} must implement #create_payment"
    end

    # Factory method pour sélectionner la bonne gateway selon ENV
    def self.build
      case ENV.fetch('SHERLOCK_GATEWAY', 'fake')
      when 'real'
        RealGateway.new
      else
        FakeGateway.new
      end
    end
  end
end

