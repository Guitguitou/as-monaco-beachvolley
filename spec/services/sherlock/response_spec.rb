# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Response do
  let(:seal) { Sherlock::Seal.new(secret: "test_secret") }
  let(:data) { "transactionReference=REF-123|responseCode=00|amount=1000" }

  describe '#valid?' do
    it 'accepte une réponse scellée avec notre secret' do
      response = described_class.new(data: data, seal_value: seal.compute(data), seal: seal)

      expect(response).to be_valid
    end

    it 'refuse une réponse dont le Data a été modifié après signature' do
      signed = seal.compute(data)
      tampered = data.sub("amount=1000", "amount=1")

      response = described_class.new(data: tampered, seal_value: signed, seal: seal)

      expect(response).not_to be_valid
    end

    it 'refuse une réponse sans sceau' do
      response = described_class.new(data: data, seal_value: "", seal: seal)

      expect(response).not_to be_valid
    end
  end

  describe '#fields' do
    it 'découpe le Data en couples clé/valeur' do
      response = described_class.new(data: data, seal_value: seal.compute(data), seal: seal)

      expect(response.fields).to include("transactionReference" => "REF-123", "responseCode" => "00")
    end
  end

  describe '#reference' do
    # La règle de résolution est détaillée dans Sherlock::Reference, testée à
    # part ; on vérifie ici qu'elle est bien appliquée à un Data réel.
    it 'retient notre référence marchande, pas celle générée par Sherlock’s' do
      data = "orderId=CP-3E77698094E61528|transactionReference=202510262319324598|responseCode=00"
      response = described_class.new(data: data, seal_value: "x", seal: seal)

      expect(response.reference).to eq("CP-3E77698094E61528")
    end

    it 'ne renvoie rien quand la réponse ne porte aucune référence' do
      response = described_class.new(data: "responseCode=00", seal_value: "x", seal: seal)

      expect(response.reference).to be_nil
    end
  end

  describe '#response_code' do
    it 'expose le code de réponse' do
      response = described_class.new(data: data, seal_value: "x", seal: seal)

      expect(response.response_code).to eq("00")
    end
  end

  describe '.from_params' do
    it 'lit les paramètres Data et Seal postés par Sherlock’s' do
      params = ActionController::Parameters.new(Data: data, Seal: seal.compute(data))

      expect(described_class.from_params(params, seal: seal)).to be_valid
    end

    it 'tolère des paramètres absents' do
      response = described_class.from_params(ActionController::Parameters.new, seal: seal)

      expect(response).not_to be_valid
      expect(response.fields).to eq({})
    end

    it 'construit son sceau depuis l’environnement par défaut' do
      with_env("SHERLOCK_API_KEY" => "test_secret", "SHERLOCK_SEAL_ALGO" => nil) do
        params = ActionController::Parameters.new(Data: data, Seal: seal.compute(data))

        expect(described_class.from_params(params)).to be_valid
      end
    end
  end
end
