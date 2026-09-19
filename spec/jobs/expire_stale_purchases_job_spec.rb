# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExpireStalePurchasesJob do
  let(:user) { create(:user) }
  let(:pack) { create(:pack, :credits, credits: 1000) }

  def purchase_created(ago, status: :pending)
    travel_to(ago.ago) { create(:credit_purchase, user: user, pack: pack, status: status) }
  end

  describe '#perform' do
    it 'clôture un achat resté en attente au-delà du délai' do
      purchase = purchase_created(described_class::STALE_AFTER + 1.minute)

      expect { described_class.perform_now }
        .to change { purchase.reload.status }.from("pending").to("cancelled")
    end

    it 'garde une trace de l’abandon' do
      purchase = purchase_created(described_class::STALE_AFTER + 1.minute)

      described_class.perform_now

      expect(purchase.reload.sherlock_fields["abandoned_at"]).to be_present
    end

    # Un paiement peut encore aboutir : on ne clôture que ce qui ne peut plus
    # recevoir de réponse.
    it 'laisse en paix un achat récent' do
      purchase = purchase_created(5.minutes)

      expect { described_class.perform_now }.not_to change { purchase.reload.status }
    end

    it 'ne touche pas aux achats déjà tranchés' do
      paid = purchase_created(described_class::STALE_AFTER + 1.minute, status: :paid)
      failed = purchase_created(described_class::STALE_AFTER + 1.minute, status: :failed)

      described_class.perform_now

      expect(paid.reload.status).to eq("paid")
      expect(failed.reload.status).to eq("failed")
    end
  end
end
