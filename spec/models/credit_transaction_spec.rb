# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditTransaction, type: :model do
  # ... existing tests ...

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:session) { create(:session, user: user) }
    let(:current_time) { Time.zone.now }
    let(:month_start) { current_time.beginning_of_month }
    let(:month_end) { current_time.end_of_month }

    let!(:training_payment) { create(:credit_transaction, transaction_type: 'training_payment', user: user, session: session) }
    let!(:free_play_payment) { create(:credit_transaction, transaction_type: 'free_play_payment', user: user, session: session) }
    let!(:private_coaching_payment) { create(:credit_transaction, transaction_type: 'private_coaching_payment', user: user, session: session) }
    let!(:purchase) { create(:credit_transaction, transaction_type: 'purchase', user: user) }
    let!(:refund) { create(:credit_transaction, transaction_type: 'refund', user: user) }
    let!(:manual_adjustment) { create(:credit_transaction, transaction_type: 'manual_adjustment', user: user) }

    let!(:current_month_payment) { create(:credit_transaction, transaction_type: 'training_payment', user: user, session: session, created_at: month_start + 1.day) }
    let!(:old_payment) { create(:credit_transaction, transaction_type: 'training_payment', user: user, session: session, created_at: 1.month.ago) }

    describe '.payments' do
      it 'returns only payment transactions' do
        result = CreditTransaction.payments
        expect(result).to include(training_payment, free_play_payment, private_coaching_payment)
        expect(result).not_to include(purchase, refund, manual_adjustment)
      end
    end

    describe '.refunds' do
      it 'returns only refund transactions' do
        result = CreditTransaction.refunds
        expect(result).to include(refund)
        expect(result).not_to include(training_payment, purchase, manual_adjustment)
      end
    end

    describe '.revenue_transactions' do
      it 'returns payment and refund transactions' do
        result = CreditTransaction.revenue_transactions
        expect(result).to include(training_payment, free_play_payment, private_coaching_payment, refund)
        expect(result).not_to include(purchase, manual_adjustment)
      end
    end

    describe '.in_period' do
      it 'returns transactions within the specified period' do
        result = CreditTransaction.in_period(month_start, month_end)
        expect(result).to include(current_month_payment)
        expect(result).not_to include(old_payment)
      end
    end
  end
end
