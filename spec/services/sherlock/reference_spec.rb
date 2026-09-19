# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Reference do
  describe '.from' do
    # Forme réelle des réponses du contrat : notre référence dans `orderId`,
    # celle générée par Sherlock's dans `transactionReference`.
    it 'préfère orderId à la référence générée par Sherlock’s' do
      fields = { "orderId" => "CP-3E77698094E61528", "transactionReference" => "202510262319324598" }

      expect(described_class.from(fields)).to eq("CP-3E77698094E61528")
    end

    it 'se rabat sur transactionReference quand orderId est absent' do
      expect(described_class.from("transactionReference" => "CP-456")).to eq("CP-456")
    end

    it 'ignore un orderId vide' do
      fields = { "orderId" => "", "transactionReference" => "CP-456" }

      expect(described_class.from(fields)).to eq("CP-456")
    end

    # Clé utilisée par le webhook historique, conservée pour ne pas casser les
    # jobs déjà en file au moment du déploiement.
    it 'accepte la clé "reference" normalisée' do
      fields = { "reference" => "CP-789", "orderId" => "CP-autre" }

      expect(described_class.from(fields)).to eq("CP-789")
    end

    it 'accepte des clés symboles' do
      expect(described_class.from(orderId: "CP-123")).to eq("CP-123")
    end

    it 'ne renvoie rien quand la réponse ne porte aucune référence' do
      expect(described_class.from("responseCode" => "00")).to be_nil
    end

    it 'ne renvoie rien pour une réponse vide' do
      expect(described_class.from({})).to be_nil
    end
  end
end
