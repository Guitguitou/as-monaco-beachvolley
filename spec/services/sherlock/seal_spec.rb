# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Seal do
  let(:data) { "amount=1000|transactionReference=REF-123" }
  let(:secret) { "test_secret" }

  describe '#compute' do
    it 'hache Data + secret avec l’algorithme historique' do
      seal = described_class.new(secret: secret)

      expect(seal.compute(data)).to eq(Digest::SHA256.hexdigest(data + secret))
    end

    it 'calcule un HMAC quand l’algorithme est HMAC-SHA-256' do
      seal = described_class.new(secret: secret, algorithm: described_class::HMAC_ALGORITHM)

      expect(seal.compute(data)).to eq(OpenSSL::HMAC.hexdigest("SHA256", secret, data))
    end
  end

  describe '#valid?' do
    let(:seal) { described_class.new(secret: secret) }

    it 'accepte un sceau calculé avec le même secret' do
      expect(seal.valid?(data, seal.compute(data))).to be(true)
    end

    it 'refuse un sceau calculé avec un autre secret' do
      forged = described_class.new(secret: "autre_secret").compute(data)

      expect(seal.valid?(data, forged)).to be(false)
    end

    it 'refuse un sceau calculé avec l’autre algorithme' do
      hmac = described_class.new(secret: secret, algorithm: described_class::HMAC_ALGORITHM).compute(data)

      expect(seal.valid?(data, hmac)).to be(false)
    end

    it 'refuse un Data absent' do
      expect(seal.valid?("", "peu importe")).to be(false)
    end

    it 'refuse un sceau absent' do
      expect(seal.valid?(data, nil)).to be(false)
    end
  end

  describe '#declared_algorithm' do
    it 'n’annonce rien pour l’algorithme historique' do
      expect(described_class.new(secret: secret).declared_algorithm).to be_nil
    end

    it 'annonce HMAC-SHA-256' do
      seal = described_class.new(secret: secret, algorithm: described_class::HMAC_ALGORITHM)

      expect(seal.declared_algorithm).to eq(described_class::HMAC_ALGORITHM)
    end
  end

  describe '.from_env' do
    it 'lit le secret et l’algorithme dans l’environnement' do
      with_env("SHERLOCK_API_KEY" => secret, "SHERLOCK_SEAL_ALGO" => described_class::HMAC_ALGORITHM) do
        expect(described_class.from_env.compute(data)).to eq(OpenSSL::HMAC.hexdigest("SHA256", secret, data))
      end
    end

    it 'retombe sur l’algorithme historique quand rien n’est configuré' do
      with_env("SHERLOCK_API_KEY" => secret, "SHERLOCK_SEAL_ALGO" => nil) do
        expect(described_class.from_env.compute(data)).to eq(Digest::SHA256.hexdigest(data + secret))
      end
    end

    it 'accepte un secret de développement en local, pour dérouler le flux sans clé LCL' do
      with_env("SHERLOCK_API_KEY" => nil) do
        expected = Digest::SHA256.hexdigest(data + described_class::DEVELOPMENT_SECRET)

        expect(described_class.from_env.compute(data)).to eq(expected)
      end
    end

    it 'échoue bruyamment si le secret manque hors développement' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

      with_env("SHERLOCK_API_KEY" => nil) do
        expect { described_class.from_env }.to raise_error(KeyError, /SHERLOCK_API_KEY/)
      end
    end
  end
end
