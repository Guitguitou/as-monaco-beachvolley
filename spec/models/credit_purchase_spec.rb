# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditPurchase, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    let(:credits_pack) { create(:pack, pack_type: 'credits') }

    it 'validates presence of required fields' do
      purchase = CreditPurchase.new
      expect(purchase).not_to be_valid
      expect(purchase.errors[:amount_cents]).to be_present
    end

    it 'validates currency is present' do
      purchase = CreditPurchase.new(amount_cents: 1000, currency: nil)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:currency]).to be_present
    end

    it 'validates amount_cents is greater than 0' do
      purchase = build(:credit_purchase, amount_cents: 0)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:amount_cents]).to be_present
    end

    it 'validates credits is greater than 0 for credits packs' do
      purchase = build(:credit_purchase, credits: 0, pack: credits_pack)
      expect(purchase).not_to be_valid
      expect(purchase.errors[:credits]).to be_present
    end
  end

  describe '#generate_reference' do
    it 'generates a unique reference on creation' do
      purchase = create(:credit_purchase, user:)
      expect(purchase.sherlock_transaction_reference).to match(/^CP-[A-F0-9]{16}$/)
    end

    it 'does not override existing reference' do
      custom_ref = "CP-CUSTOM123"
      purchase = create(:credit_purchase, user:, sherlock_transaction_reference: custom_ref)
      expect(purchase.sherlock_transaction_reference).to eq(custom_ref)
    end
  end

  describe '#credit!' do
    let(:credits_pack) { create(:pack, pack_type: 'credits') }

    it 'credits the user account once (idempotent)' do
      purchase = create(:credit_purchase, user:, pack: credits_pack, amount_cents: 1000, credits: 1000)

      expect { purchase.credit! }.to change { user.reload.balance&.amount.to_i }.by(1000)
      expect(purchase.reload.status).to eq("paid")
      expect(purchase.paid_at).to be_present

      # Idempotence: calling again should not credit twice
      expect { purchase.credit! }.not_to change { user.reload.balance&.amount.to_i }
    end

    it 'creates a credit_transaction with type purchase' do
      purchase = create(:credit_purchase, user:, pack: credits_pack, credits: 1000)

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
      purchase = create(:credit_purchase, user:)

      purchase.send(:mark_as_failed!, reason: "Card declined")

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

  describe 'Licence purchase activation' do
    let(:licence_pack) { create(:pack, pack_type: 'licence') }
    let(:inactive_user) do
      u = create(:user, activated_at: nil)
      u.update_column(:activated_at, nil) # Bypass callbacks
      u
    end

    it 'activates user account when licence is paid' do
      purchase = create(:credit_purchase, user: inactive_user, pack: licence_pack, credits: 0)

      expect(inactive_user.activated?).to be false

      purchase.credit!

      expect(inactive_user.reload.activated?).to be true
      expect(purchase.reload.status).to eq('paid')
    end

    it 'does not reactivate already activated account' do
      activated_user = create(:user, activated_at: 2.days.ago)
      original_time = activated_user.activated_at

      purchase = create(:credit_purchase, user: activated_user, pack: licence_pack, credits: 0)
      purchase.credit!

      expect(activated_user.reload.activated_at).to be_within(1.second).of(original_time)
    end
  end
end
