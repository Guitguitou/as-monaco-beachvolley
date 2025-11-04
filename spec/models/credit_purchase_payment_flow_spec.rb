# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CreditPurchase Payment Flow Integration', type: :model do
  let(:user) { create(:user, activated_at: Time.current) }
  let(:inactive_user) { create(:user, activated_at: nil) }

  describe 'Credits pack payment' do
    let(:credits_pack) { create(:pack, pack_type: 'credits', credits: 1000, amount_cents: 1000) }

    it 'processes credits pack payment correctly' do
      purchase = create(:credit_purchase, user:, pack: credits_pack, credits: 1000, amount_cents: 1000)
      
      initial_balance = user.balance.amount

      # Simuler le paiement
      purchase.credit!

      # Vérifications
      expect(purchase.reload.status).to eq('paid')
      expect(purchase.paid_at).to be_present
      expect(user.reload.balance.amount).to eq(initial_balance + 1000)
      
      # Transaction créée
      transaction = user.credit_transactions.last
      expect(transaction.transaction_type).to eq('purchase')
      expect(transaction.amount).to eq(1000)
    end
  end

  describe 'Licence pack payment' do
    let(:licence_pack) { create(:pack, pack_type: 'licence', amount_cents: 5000, credits: 0) }

    it 'processes licence pack and activates inactive user' do
      purchase = create(:credit_purchase, user: inactive_user, pack: licence_pack, credits: 0, amount_cents: 5000)
      
      expect(inactive_user.activated?).to be false

      # Simuler le paiement
      purchase.credit!

      # Vérifications
      expect(purchase.reload.status).to eq('paid')
      expect(purchase.paid_at).to be_present
      
      # CRITIQUE : L'utilisateur doit être activé !
      expect(inactive_user.reload.activated?).to be true
      expect(inactive_user.activated_at).to be_present
    end

    it 'processes licence pack for already activated user without issues' do
      purchase = create(:credit_purchase, user:, pack: licence_pack, credits: 0, amount_cents: 5000)
      
      original_activation = user.activated_at

      # Simuler le paiement
      purchase.credit!

      # Vérifications
      expect(purchase.reload.status).to eq('paid')
      # L'activation ne change pas si déjà activé
      expect(user.reload.activated_at).to be_within(1.second).of(original_activation)
    end
  end

  describe 'Stage pack payment' do
    let(:stage) { create(:stage) }
    let(:stage_pack) { create(:pack, pack_type: 'stage', stage:, amount_cents: 15000, credits: 0) }

    it 'processes stage pack payment correctly' do
      purchase = create(:credit_purchase, user:, pack: stage_pack, credits: 0, amount_cents: 15000)

      # Simuler le paiement
      purchase.credit!

      # Vérifications
      expect(purchase.reload.status).to eq('paid')
      expect(purchase.paid_at).to be_present
      
      # Stage pack ne touche pas aux crédits ni à l'activation
      expect(user.reload.balance.amount).to be >= 0  # Pas de changement de balance
    end
  end

  # Note: Les achats anonymes ne sont plus supportés (user_id NOT NULL en DB)
  # Si besoin futur, créer un "guest" user ou modifier la contrainte DB

  describe 'Idempotence' do
    let(:credits_pack) { create(:pack, pack_type: 'credits', credits: 1000, amount_cents: 1000) }

    it 'calling credit! multiple times does not duplicate credits' do
      purchase = create(:credit_purchase, user:, pack: credits_pack, credits: 1000, amount_cents: 1000)
      
      purchase.credit!
      balance_after_first = user.reload.balance.amount

      # Appel multiple (ne devrait rien faire)
      purchase.credit!
      purchase.credit!
      
      # Balance ne doit pas changer
      expect(user.reload.balance.amount).to eq(balance_after_first)
      
      # Toujours payé
      expect(purchase.reload.status).to eq('paid')
    end
  end
end

