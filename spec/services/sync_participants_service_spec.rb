# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncParticipantsService, type: :service do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player1) { create(:user, level: level) }
  let(:player2) { create(:user, level: level) }
  let(:session_record) do
    create(:session,
           session_type: 'entrainement',
           terrain: 'Terrain 1',
           user: coach,
           levels: [level])
  end

  before do
    create(:credit_transaction, user: player1, amount: 1_000)
    create(:credit_transaction, user: player2, amount: 1_000)
  end

  describe '#call' do
    context 'when adding participants' do
      it 'adds new participants and creates transactions' do
        participant_ids = [player1.id, player2.id]

        result = SyncParticipantsService.new(
          session_record,
          participant_ids,
          can_manage_registrations: true,
          can_bypass_deadline: true
        ).call

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
        expect(session_record.reload.participants).to contain_exactly(player1, player2)
        expect(player1.reload.credit_transactions.count).to eq(2) # initial + payment
      end

      it 'handles errors gracefully' do
        # Create a session that's already full
        session_record.update!(max_players: 1)
        create(:registration, user: player1, session: session_record, status: :confirmed)
        participant_ids = [player2.id]

        result = SyncParticipantsService.new(
          session_record,
          participant_ids,
          can_manage_registrations: true,
          can_bypass_deadline: true
        ).call

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
      end
    end

    context 'when removing participants' do
      before do
        create(:registration, user: player1, session: session_record, status: :confirmed)
        create(:registration, user: player2, session: session_record, status: :confirmed)
      end

      it 'removes participants and refunds transactions' do
        initial_balance = player1.reload.balance.amount
        participant_ids = [player2.id] # Keep only player2

        result = SyncParticipantsService.new(
          session_record,
          participant_ids,
          can_manage_registrations: true,
          can_bypass_deadline: true
        ).call

        expect(result[:success]).to be true
        expect(session_record.reload.participants).to contain_exactly(player2)
        expect(player1.reload.balance.amount).to eq(initial_balance + session_record.price)
      end
    end

    context 'when adding and removing simultaneously' do
      before do
        create(:registration, user: player1, session: session_record, status: :confirmed)
      end

      it 'handles both operations correctly' do
        participant_ids = [player2.id] # Remove player1, add player2

        result = SyncParticipantsService.new(
          session_record,
          participant_ids,
          can_manage_registrations: true,
          can_bypass_deadline: true
        ).call

        expect(result[:success]).to be true
        expect(session_record.reload.participants).to contain_exactly(player2)
      end
    end
  end
end

