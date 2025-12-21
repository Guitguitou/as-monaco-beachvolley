# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionCancellationService, type: :service do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player1) { create(:user, level: level) }
  let(:player2) { create(:user, level: level) }
  let(:session_record) do
    create(:session,
           session_type: 'entrainement',
           terrain: 'Terrain 1',
           user: coach,
           levels: [ level ])
  end

  before do
    create(:credit_transaction, user: player1, amount: 1_000)
    create(:credit_transaction, user: player2, amount: 1_000)
  end

  describe '#call' do
    context 'when session has registrations' do
      before do
        create(:registration, user: player1, session: session_record, status: :confirmed)
        create(:registration, user: player2, session: session_record, status: :confirmed)
      end

      it 'cancels session and refunds all participants' do
        initial_balance1 = player1.reload.balance.amount
        initial_balance2 = player2.reload.balance.amount

        result = SessionCancellationService.new(session_record).call

        expect(result[:success]).to be true
        expect(Session.exists?(session_record.id)).to be false
        expect(player1.reload.balance.amount).to eq(initial_balance1 + session_record.price)
        expect(player2.reload.balance.amount).to eq(initial_balance2 + session_record.price)
      end

      it 'detaches transactions from session' do
        SessionCancellationService.new(session_record).call

        expect(CreditTransaction.where(session_id: session_record.id).count).to eq(0)
      end
    end

    context 'when session is a private coaching' do
      let(:private_session) do
        create(:session,
               session_type: 'coaching_prive',
               terrain: 'Terrain 1',
               user: coach,
               levels: [ level ])
      end

      it 'refunds the coach for the debit done at creation' do
        initial_balance = coach.reload.balance.amount
        coach_amount = private_session.send(:default_price)

        result = SessionCancellationService.new(private_session).call

        expect(result[:success]).to be true
        expect(coach.reload.balance.amount).to eq(initial_balance + coach_amount)
      end
    end

    context 'when session has no registrations' do
      it 'successfully cancels the session' do
        result = SessionCancellationService.new(session_record).call

        expect(result[:success]).to be true
        expect(Session.exists?(session_record.id)).to be false
      end
    end
  end
end
