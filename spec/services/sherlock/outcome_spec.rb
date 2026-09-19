# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::Outcome do
  describe '#to_sym' do
    it 'ne retient "00" que comme paiement accepté' do
      expect(described_class.new("responseCode" => "00").to_sym).to eq(:paid)
    end

    it 'traite "17" comme une annulation par le client' do
      expect(described_class.new("responseCode" => "17").to_sym).to eq(:cancelled)
    end

    # Le refus le plus courant. Avant, il n'était pas reconnu et laissait
    # l'achat bloqué en `pending` pour toujours.
    it 'traite "05" comme un refus' do
      expect(described_class.new("responseCode" => "05").to_sym).to eq(:failed)
    end

    it 'traite en refus tous les autres codes documentés' do
      codes = described_class::CODE_LABELS.keys - [ "00", "17" ]

      outcomes = codes.index_with { |code| described_class.new("responseCode" => code).to_sym }

      expect(outcomes.values).to all(eq(:failed))
    end

    it 'traite en refus un code inconnu plutôt que de laisser l’achat en attente' do
      expect(described_class.new("responseCode" => "42").to_sym).to eq(:failed)
    end

    it 'ignore les espaces autour du code' do
      expect(described_class.new("responseCode" => " 00 ").to_sym).to eq(:paid)
    end

    context 'sans responseCode' do
      it 'accepte AUTHORISED, l’orthographe de Sherlock’s' do
        expect(described_class.new("transactionStatus" => "AUTHORISED").to_sym).to eq(:paid)
      end

      it 'accepte AUTHORIZED, l’orthographe des autres passerelles' do
        expect(described_class.new("transactionStatus" => "AUTHORIZED").to_sym).to eq(:paid)
      end

      it 'accepte TO_CAPTURE et CAPTURED' do
        expect(described_class.new("transactionStatus" => "TO_CAPTURE").to_sym).to eq(:paid)
        expect(described_class.new("transactionStatus" => "CAPTURED").to_sym).to eq(:paid)
      end

      it 'reconnaît une annulation' do
        expect(described_class.new("transactionStatus" => "CANCELLED").to_sym).to eq(:cancelled)
      end

      it 'accepte le statut normalisé du webhook' do
        expect(described_class.new("status" => "paid").to_sym).to eq(:paid)
      end

      it 'refuse un statut inconnu' do
        expect(described_class.new("transactionStatus" => "WHATEVER").to_sym).to eq(:failed)
      end

      it 'refuse une réponse vide' do
        expect(described_class.new({}).to_sym).to eq(:failed)
      end
    end

    it 'donne la priorité au responseCode sur le transactionStatus' do
      outcome = described_class.new("responseCode" => "05", "transactionStatus" => "AUTHORISED")

      expect(outcome.to_sym).to eq(:failed)
    end
  end

  describe 'prédicats' do
    it 'expose l’issue sous forme de prédicats' do
      expect(described_class.new("responseCode" => "00")).to be_paid
      expect(described_class.new("responseCode" => "17")).to be_cancelled
      expect(described_class.new("responseCode" => "05")).to be_failed
    end
  end

  describe '#reason' do
    it 'reprend le libellé officiel du code' do
      expect(described_class.new("responseCode" => "05").reason).to eq("Autorisation refusée")
    end

    it 'cite le code quand il n’est pas documenté' do
      expect(described_class.new("responseCode" => "42").reason).to eq("Paiement refusé (code 42)")
    end

    it 'reprend le message d’erreur transmis à défaut de code' do
      outcome = described_class.new("errorMessage" => "Fonds insuffisants")

      expect(outcome.reason).to eq("Fonds insuffisants")
    end

    it 'se rabat sur responseMessage' do
      outcome = described_class.new("responseMessage" => "Carte refusée")

      expect(outcome.reason).to eq("Carte refusée")
    end

    it 'cite le statut quand aucun message n’est transmis' do
      outcome = described_class.new("transactionStatus" => "REFUSED")

      expect(outcome.reason).to eq("Paiement refusé (statut refused)")
    end

    it 'reste explicite quand la réponse ne dit rien' do
      expect(described_class.new({}).reason).to eq("Paiement refusé sans motif transmis")
    end
  end
end
