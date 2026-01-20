require "rails_helper"
require "sib-api-v3-sdk"

RSpec.describe Brevo::TransactionalEmail, type: :service do
  let(:api) { instance_double(Brevo::TransactionalEmailsApi) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:service) { described_class.new(api: api, logger: logger) }
  let(:user) { create(:user, first_name: "Jane", last_name: "Doe", email: "jane@example.com") }
  let(:paid_at) { Time.zone.parse("2024-01-02 10:00:00") }
  let(:credit_purchase) do
    create(
      :credit_purchase,
      :paid,
      user: user,
      credits: 1500,
      amount_cents: 1500,
      sherlock_transaction_reference: "CP-ABC123",
      paid_at: paid_at
    )
  end
  let(:template_id) { 123 }
  let(:sender_email) { "payments@example.com" }
  let(:sender_name) { "Beach Volley" }

  before do
    allow(ENV).to receive(:fetch).with("BREVO_TEMPLATE_PAYMENT_SUCCESS").and_return(template_id.to_s)
    allow(ENV).to receive(:fetch).with("BREVO_SENDER_EMAIL").and_return(sender_email)
    allow(ENV).to receive(:fetch).with("BREVO_SENDER_NAME").and_return(sender_name)
  end

  describe "#send_payment_confirmation" do
    context "with valid configuration" do
      it "builds and sends the transactional email with expected params" do
        expect(api).to receive(:send_transac_email) do |payload|
          expect(payload.template_id).to eq(template_id)
          expect(payload.to.first[:email]).to eq(user.email)
          expect(payload.to.first[:name]).to eq(user.full_name)
          expect(payload.sender[:email]).to eq(sender_email)
          expect(payload.sender[:name]).to eq(sender_name)
          expect(payload.params).to include(
            user_first_name: "Jane",
            user_last_name: "Doe",
            purchase_reference: "CP-ABC123",
            credits: 1500,
            amount_eur: "15.00",
            paid_at_iso: paid_at.iso8601
          )
        end
        expect(logger).to receive(:info).with("[Brevo] Transactional email sent with template #{template_id} to #{user.email}")

        service.send_payment_confirmation(credit_purchase)
      end
    end

    context "when template id is missing" do
      it "raises a MissingConfigError" do
        allow(ENV).to receive(:fetch).with("BREVO_TEMPLATE_PAYMENT_SUCCESS").and_raise(KeyError)

        expect {
          service.send_payment_confirmation(credit_purchase)
        }.to raise_error(described_class::MissingConfigError, /template id/)
      end
    end

    context "when credit purchase has no user" do
      it "skips sending and returns nil" do
        purchase_without_user = build_stubbed(:credit_purchase, :paid, user: nil)
        expect(api).not_to receive(:send_transac_email)

        result = service.send_payment_confirmation(purchase_without_user)

        expect(result).to be_nil
      end
    end

    context "when Brevo API returns an error" do
      it "logs and re-raises the error for retries" do
        allow(api).to receive(:send_transac_email).and_raise(Brevo::ApiError.new(code: 400, response_body: "Bad Request"))
        expect(logger).to receive(:error).with(/Failed to send transactional email/)

        expect {
          service.send_payment_confirmation(credit_purchase)
        }.to raise_error(Brevo::ApiError)
      end
    end
  end
end
