require 'rails_helper'

RSpec.describe CreditPurchase, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'validates presence of required fields' do
      purchase = CreditPurchase.new
      expect(purchase).not_to be_valid
      expect(purchase.errors[:amount_cents]).to include("can't be blank")
      expect(purchase.errors[:currency]).to include("can't be blank")
      expect(purchase.errors[:credits]).to include("can't be blank")
    end

    it 'validates amount_cents is greater than 0' do
      purchase = build(:credit_purchase, amount_cents: 0)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:amount_cents]).to include("must be greater than 0")
    end

    it 'validates credits is greater than 0' do
      purchase = build(:credit_purchase, credits: 0)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:credits]).to include("must be greater than 0")
    end
  end

  describe '#generate_reference' do
    it 'generates a unique reference on creation' do
      purchase = create(:credit_purchase, user: user)
      expect(purchase.sherlock_transaction_reference).to match(/^CP-[A-F0-9]{16}$/)
    end

    it 'does not override existing reference' do
      custom_ref = "CP-CUSTOM123"
      purchase = create(:credit_purchase, user: user, sherlock_transaction_reference: custom_ref)
      expect(purchase.sherlock_transaction_reference).to eq(custom_ref)
    end
  end

  describe '#credit!' do
    it 'credits the user account once (idempotent)' do
      purchase = create(:credit_purchase, user: user, amount_cents: 1000, credits: 1000)
      
      expect { purchase.credit! }.to change { user.reload.balance&.amount.to_i }.by(1000)
      expect(purchase.reload.status).to eq("paid")
      expect(purchase.paid_at).to be_present
      
      # Idempotence: calling again should not credit twice
      expect { purchase.credit! }.not_to change { user.reload.balance&.amount.to_i }
    end

    it 'creates a credit_transaction with type purchase' do
      purchase = create(:credit_purchase, user: user, credits: 1000)
      
      expect {
        purchase.credit!
      }.to change { user.credit_transactions.count }.by(1)
      
      transaction = user.credit_transactions.last
      expect(transaction.transaction_type).to eq("purchase")
      expect(transaction.amount).to eq(1000)
    end
  end

  describe '#mark_as_failed!' do
    it 'marks purchase as failed with reason' do
      purchase = create(:credit_purchase, user: user)
      
      purchase.mark_as_failed!(reason: "Card declined")
      
      expect(purchase.status).to eq("failed")
      expect(purchase.failed_at).to be_present
      expect(purchase.sherlock_fields["failure_reason"]).to eq("Card declined")
    end
  end

  describe '.create_pack_10_eur' do
    it 'creates a 10 EUR pack with 1000 credits' do
      purchase = CreditPurchase.create_pack_10_eur(user: user)
      
      expect(purchase.amount_cents).to eq(1000)
      expect(purchase.currency).to eq("EUR")
      expect(purchase.credits).to eq(1000)
      expect(purchase.status).to eq("pending")
      expect(purchase.amount_eur).to eq(10.0)
    end
  end

  describe '#amount_eur' do
    it 'converts cents to euros' do
      purchase = build(:credit_purchase, amount_cents: 1000)
      expect(purchase.amount_eur).to eq(10.0)
    end
  end
end
