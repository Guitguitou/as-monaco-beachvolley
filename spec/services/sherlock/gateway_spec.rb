# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Gateway do
  describe '.build' do
    it 'renvoie la vraie passerelle quand SHERLOCK_GATEWAY vaut "real"' do
      with_env("SHERLOCK_GATEWAY" => "real") do
        expect(described_class.build).to be_a(Sherlock::RealGateway)
      end
    end

    it 'renvoie la passerelle simulée quand SHERLOCK_GATEWAY vaut "fake"' do
      with_env("SHERLOCK_GATEWAY" => "fake") do
        expect(described_class.build).to be_a(Sherlock::FakeGateway)
      end
    end

    # Choix volontaire : sans configuration explicite, on ne part jamais vers
    # une vraie page de paiement.
    it 'se rabat sur la passerelle simulée quand rien n’est configuré' do
      with_env("SHERLOCK_GATEWAY" => nil) do
        expect(described_class.build).to be_a(Sherlock::FakeGateway)
      end
    end
  end

  describe '#create_payment' do
    it 'reste abstraite' do
      expect {
        described_class.new.create_payment(
          reference: "ref",
          amount_cents: 1000,
          currency: "EUR",
          return_urls: {},
          customer: {}
        )
      }.to raise_error(NotImplementedError)
    end
  end
end
