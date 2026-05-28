# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/support/shared_examples/captive_footer")

RSpec.describe PaymentMailer, type: :mailer do
  describe "#payment_accepted" do
    let(:user) { create(:user, first_name: "Alice", email: "alice@example.com") }

    context "when the purchase is a credits pack" do
      let(:pack) { create(:pack, :credits) }
      let(:credit_purchase) do
        create(:credit_purchase, :paid, user: user, pack: pack, credits: 500, amount_cents: 500)
      end

      subject(:mail) { described_class.payment_accepted(credit_purchase) }

      it "sends a credits confirmation email to the buyer with the purchase details" do
        expect(mail.to).to eq([ user.email ])
        expect(mail.subject).to eq("Paiement accepté – 500 crédits reçus")

        html_body = mail.html_part.body.to_s
        expect(html_body).to include("Bonjour Alice")
        expect(html_body).to include("Votre paiement a bien été accepté")
        expect(html_body).to include("500")
        expect(html_body).to include(credit_purchase.sherlock_transaction_reference)
      end

      it_behaves_like "includes the Captive footer"
    end

    context "when the purchase is not a credits pack" do
      let(:credit_purchase) { create(:credit_purchase, :paid, user: user, pack: nil) }

      subject(:mail) { described_class.payment_accepted(credit_purchase) }

      it "sends a generic payment confirmation without the credits line" do
        expect(mail.to).to eq([ user.email ])
        expect(mail.subject).to eq("Paiement accepté")

        html_body = mail.html_part.body.to_s
        expect(html_body).to include("Votre paiement a bien été accepté")
        expect(html_body).to include("Montant")
        expect(html_body).not_to match(/\d+ crédits ont été ajoutés/)
      end

      it_behaves_like "includes the Captive footer"
    end

    context "when the credit purchase has no user" do
      it "returns early and does not deliver any email" do
        credit_purchase = create(:credit_purchase, user: user)
        allow(credit_purchase).to receive(:user).and_return(nil)

        expect {
          described_class.payment_accepted(credit_purchase).deliver_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
