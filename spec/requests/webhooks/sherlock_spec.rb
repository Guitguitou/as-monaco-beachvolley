# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Webhooks::Sherlock", type: :request do
  let(:user) { create(:user) }
  let(:credit_purchase) { create(:credit_purchase, user: user, sherlock_transaction_reference: "REF-123") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("SHERLOCK_API_KEY").and_return("test_secret")
    allow(ENV).to receive(:fetch).with("SHERLOCK_SEAL_ALGO", anything).and_return("sha256")
    allow(SherlockCallbackJob).to receive(:perform_later)
  end

  describe "POST /webhooks/sherlock" do
    let(:data_string) { "orderId=REF-123|transactionStatus=ACCEPTED|responseCode=00" }
    let(:seal) { Digest::SHA256.hexdigest(data_string + "test_secret") }

    context "with valid seal" do
      it "returns http success" do
        post webhooks_sherlock_path, params: { Data: data_string, Seal: seal }
        expect(response).to have_http_status(:ok)
      end

      it "enqueues SherlockCallbackJob" do
        expect(SherlockCallbackJob).to receive(:perform_later).with(
          hash_including("reference" => "REF-123")
        )
        post webhooks_sherlock_path, params: { Data: data_string, Seal: seal }
      end
    end

    context "with missing Data" do
      it "returns bad request" do
        post webhooks_sherlock_path, params: { Seal: seal }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with missing Seal" do
      it "returns bad request" do
        post webhooks_sherlock_path, params: { Data: data_string }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid seal" do
      it "returns unauthorized" do
        post webhooks_sherlock_path, params: { Data: data_string, Seal: "invalid_seal" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with HMAC-SHA-256 algorithm" do
      let(:seal) { OpenSSL::HMAC.hexdigest("SHA256", "test_secret", data_string) }

      before do
        allow(ENV).to receive(:fetch).with("SHERLOCK_SEAL_ALGO", anything).and_return("HMAC-SHA-256")
      end

      it "validates seal correctly" do
        post webhooks_sherlock_path, params: { Data: data_string, Seal: seal }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when an error occurs" do
      before do
        allow(Sherlock::DataParser).to receive(:parse).and_raise(StandardError.new("Parse error"))
        allow(Rails.logger).to receive(:error)
      end

      it "returns internal server error" do
        post webhooks_sherlock_path, params: { Data: data_string, Seal: seal }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
