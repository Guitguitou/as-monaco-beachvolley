# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::ApplyOutcome do
  let(:user) { create(:user) }
  let(:pack) { create(:pack, :credits, credits: 1000) }
  let(:purchase) do
    create(:credit_purchase, user: user, pack: pack, credits: 1000, sherlock_transaction_reference: "REF-123")
  end

  describe '.call' do
    context 'quand la banque accepte' do
      let(:fields) { { "responseCode" => "00", "transactionReference" => "REF-123" } }

      it 'marque l’achat payé' do
        expect { described_class.call(purchase: purchase, fields: fields) }
          .to change { purchase.reload.status }.from("pending").to("paid")

        expect(purchase.paid_at).to be_present
      end

      it 'crédite le solde du joueur' do
        expect { described_class.call(purchase: purchase, fields: fields) }
          .to change { user.reload.balance&.amount.to_i }.by(1000)
      end

      it 'déclenche l’email de confirmation' do
        expect(PostPaymentFulfillmentJob).to receive(:perform_later).with(purchase.id)

        described_class.call(purchase: purchase, fields: fields)
      end

      it 'renvoie l’issue appliquée' do
        expect(described_class.call(purchase: purchase, fields: fields)).to eq(:paid)
      end

      # Le retour navigateur et le webhook arrivent tous les deux ici, dans un
      # ordre imprévisible : le second passage ne doit rien recréditer.
      it 'ne crédite qu’une fois, quel que soit le nombre de notifications' do
        described_class.call(purchase: purchase, fields: fields)

        expect { described_class.call(purchase: purchase.reload, fields: fields) }
          .not_to change { user.reload.balance&.amount.to_i }
      end

      it 'n’envoie l’email qu’une fois' do
        described_class.call(purchase: purchase, fields: fields)

        expect(PostPaymentFulfillmentJob).not_to receive(:perform_later)
        described_class.call(purchase: purchase.reload, fields: fields)
      end
    end

    context 'quand le client annule' do
      let(:fields) { { "responseCode" => "17", "transactionReference" => "REF-123" } }

      it 'marque l’achat annulé' do
        expect { described_class.call(purchase: purchase, fields: fields) }
          .to change { purchase.reload.status }.from("pending").to("cancelled")
      end

      it 'ne crédite rien' do
        expect { described_class.call(purchase: purchase, fields: fields) }
          .not_to change { user.reload.balance&.amount.to_i }
      end
    end

    context 'quand la banque refuse' do
      let(:fields) { { "responseCode" => "05", "transactionReference" => "REF-123" } }

      it 'marque l’achat en échec' do
        expect { described_class.call(purchase: purchase, fields: fields) }
          .to change { purchase.reload.status }.from("pending").to("failed")

        expect(purchase.failed_at).to be_present
      end

      it 'enregistre le motif transmis par la banque' do
        described_class.call(purchase: purchase, fields: fields)

        expect(purchase.reload.failure_reason).to eq("Autorisation refusée")
      end
    end

    # Une notification de refus en retard ne doit jamais effacer un
    # encaissement déjà comptabilisé.
    context 'quand une notification tardive contredit un paiement déjà encaissé' do
      before do
        described_class.call(purchase: purchase, fields: { "responseCode" => "00", "transactionReference" => "REF-123" })
      end

      it 'reste payé face à un refus' do
        expect { described_class.call(purchase: purchase.reload, fields: { "responseCode" => "05" }) }
          .not_to change { purchase.reload.status }
      end

      it 'reste payé face à une annulation' do
        expect { described_class.call(purchase: purchase.reload, fields: { "responseCode" => "17" }) }
          .not_to change { purchase.reload.status }
      end
    end

    it 'trace la réponse brute pour l’audit' do
      fields = { "responseCode" => "00", "transactionReference" => "REF-123" }

      described_class.call(purchase: purchase, fields: fields)

      expect(purchase.reload.sherlock_fields["callback"]).to eq(fields)
      expect(purchase.sherlock_fields["received_at"]).to be_present
    end
  end
end
