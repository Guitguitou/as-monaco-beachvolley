require "rails_helper"

RSpec.describe PaymentMailer, type: :mailer do
  describe "#payment_accepted" do
    it "uses credits subject for a credits pack purchase" do
      credits_pack = create(:pack, :credits, credits: 20, amount_cents: 5000)
      purchase = create(:credit_purchase, pack: credits_pack, credits: 20, amount_cents: 5000)

      mail = described_class.payment_accepted(purchase)

      expect(mail.to).to eq([purchase.user.email])
      expect(mail.subject).to eq("Paiement accepté – 20 crédits reçus")
      expect(mail.text_part.decoded).to include("20 crédits ont été ajoutés")
    end

    it "uses generic subject for non-credits purchase" do
      pack = create(:pack, :licence)
      purchase = create(:credit_purchase, pack: pack, credits: 0, amount_cents: 2500)

      mail = described_class.payment_accepted(purchase)

      expect(mail.subject).to eq("Paiement accepté")
    end
  end
end
