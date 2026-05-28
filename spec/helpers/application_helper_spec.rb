# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#level_badge' do
    let(:level) { create(:level, name: "G1", color: "#10B981") }

    it 'returns a span with level name and color' do
      result = helper.level_badge(level)

      expect(result).to include(level.name)
      expect(result).to include(level.color)
      expect(result).to include("inline-flex")
    end
  end

  describe '#get_session_type_label' do
    it 'returns correct label for entrainement' do
      expect(helper.get_session_type_label('entrainement')).to eq('Entraînement')
    end

    it 'returns correct label for jeu_libre' do
      expect(helper.get_session_type_label('jeu_libre')).to eq('Jeu libre')
    end

    it 'returns correct label for tournoi' do
      expect(helper.get_session_type_label('tournoi')).to eq('Tournoi')
    end

    it 'returns correct label for coaching_prive' do
      expect(helper.get_session_type_label('coaching_prive')).to eq('Coaching privé')
    end

    it 'returns humanized version for unknown types' do
      expect(helper.get_session_type_label('unknown_type')).to eq('Unknown type')
    end
  end

  describe '#session_type_icon' do
    it 'returns correct icon for entrainement' do
      expect(helper.session_type_icon('entrainement')).to eq('dumbbell')
    end

    it 'returns correct icon for jeu_libre' do
      expect(helper.session_type_icon('jeu_libre')).to eq('volleyball')
    end

    it 'returns correct icon for tournoi' do
      expect(helper.session_type_icon('tournoi')).to eq('trophy')
    end

    it 'returns correct icon for coaching_prive' do
      expect(helper.session_type_icon('coaching_prive')).to eq('shield-user')
    end

    it 'returns default icon for unknown types' do
      expect(helper.session_type_icon('unknown_type')).to eq('volleyball')
    end
  end

  describe '#get_session_type_classes' do
    it 'returns correct classes for entrainement' do
      expect(helper.get_session_type_classes('entrainement')).to eq('bg-green-100 text-green-800')
    end

    it 'returns correct classes for jeu_libre' do
      expect(helper.get_session_type_classes('jeu_libre')).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns correct classes for tournoi' do
      expect(helper.get_session_type_classes('tournoi')).to eq('bg-purple-100 text-purple-800')
    end

    it 'returns correct classes for coaching_prive' do
      expect(helper.get_session_type_classes('coaching_prive')).to eq('bg-orange-100 text-orange-800')
    end

    it 'returns default classes for unknown types' do
      expect(helper.get_session_type_classes('unknown_type')).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#humanize_credit_transaction_type' do
    it 'returns correct label for purchase' do
      expect(helper.humanize_credit_transaction_type('purchase')).to eq('Achat')
    end

    it 'returns correct label for training_payment' do
      expect(helper.humanize_credit_transaction_type('training_payment')).to eq("Paiement d'entraînement")
    end

    it 'returns correct label for free_play_payment' do
      expect(helper.humanize_credit_transaction_type('free_play_payment')).to eq('Paiement de jeu libre')
    end

    it 'returns correct label for private_coaching_payment' do
      expect(helper.humanize_credit_transaction_type('private_coaching_payment')).to eq('Paiement de coaching privé')
    end

    it 'returns correct label for refund' do
      expect(helper.humanize_credit_transaction_type('refund')).to eq('Remboursement')
    end

    it 'returns correct label for manual_adjustment' do
      expect(helper.humanize_credit_transaction_type('manual_adjustment')).to eq("Ajustement de l'admin")
    end

    it 'returns default label for unknown types' do
      expect(helper.humanize_credit_transaction_type('unknown')).to eq('Transaction')
    end
  end

  describe '#external_url?' do
    it 'returns true for external URL with different host' do
      allow(helper).to receive(:request).and_return(double(host: 'example.com'))
      expect(helper.external_url?('https://google.com')).to be true
    end

    it 'returns false for same host with scheme' do
      allow(helper).to receive(:request).and_return(double(host: 'example.com'))
      expect(helper.external_url?('https://example.com/path')).to be false
    end

    it 'returns false for same host without scheme' do
      allow(helper).to receive(:request).and_return(double(host: 'example.com'))
      expect(helper.external_url?('//example.com/path')).to be false
    end

    it 'returns false for blank URL' do
      expect(helper.external_url?('')).to be false
      expect(helper.external_url?(nil)).to be false
    end

    it 'returns false for invalid URL' do
      expect(helper.external_url?('not a url')).to be false
    end
  end
end
