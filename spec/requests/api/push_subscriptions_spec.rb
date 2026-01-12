# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::PushSubscriptions", type: :request do
  let(:user) { create(:user) }
  let(:subscription_params) do
    {
      push_subscription: {
        endpoint: "https://fcm.googleapis.com/fcm/send/test123",
        p256dh: Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false),
        auth: Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false)
      }
    }
  end

  before do
    sign_in user
  end

  describe "POST /api/push_subscriptions" do
    context "with valid parameters" do
      it "creates a new push subscription" do
        expect {
          post "/api/push_subscriptions", params: subscription_params, as: :json
        }.to change { user.push_subscriptions.count }.by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
      end

      it "updates existing subscription with same endpoint" do
        existing = create(:push_subscription, user: user, endpoint: subscription_params[:push_subscription][:endpoint])

        expect {
          post "/api/push_subscriptions", params: subscription_params, as: :json
        }.not_to change { user.push_subscriptions.count }

        expect(existing.reload.p256dh).to eq(subscription_params[:push_subscription][:p256dh])
      end
    end

    context "with invalid parameters" do
      it "returns error when endpoint is missing" do
        post "/api/push_subscriptions", params: { push_subscription: { p256dh: "test", auth: "test" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "requires authentication" do
        post "/api/push_subscriptions", params: subscription_params, as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /api/push_subscriptions" do
    let!(:subscription) { create(:push_subscription, user: user) }

    it "deletes the subscription" do
      delete_params = { endpoint: subscription.endpoint }
      expect {
        delete "/api/push_subscriptions", params: delete_params, as: :json
      }.to change { user.push_subscriptions.count }.by(-1)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("success")
    end

    it "returns error when subscription not found" do
      delete "/api/push_subscriptions", params: { endpoint: "nonexistent" }, as: :json

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("error")
    end
  end
end
