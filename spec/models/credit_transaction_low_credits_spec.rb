# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CreditTransaction low credits notification", type: :model do
  let(:user) { create(:user) }

  before do
    # Mock VAPID keys
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("test_public_key")
    allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("test_private_key")
    allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:test@example.com")

    # Mock cache
    allow(Rails.cache).to receive(:read).and_return(nil)
    allow(Rails.cache).to receive(:write)

    # Mock the job
    allow(SendPushNotificationJob).to receive(:perform_later)
  end

  describe "Règle 3: Crédits faibles (< 500)" do
    context "when balance drops below 500" do
      it "sends notification when passing from >= 500 to < 500" do
        # Start with 600 credits
        create(:credit_transaction, user: user, amount: 600)

        # Spend 200 credits (balance goes from 600 to 400)
        create(:credit_transaction, user: user, amount: -200)

        expect(SendPushNotificationJob).to have_received(:perform_later).with(
          user.id,
          hash_including(
            title: "Crédits faibles",
            body: "Attention tu as moins de 500 crédits, pense à recharger 😉"
          )
        )
      end

      it "does not send notification when already below 500" do
        # Start with 300 credits
        create(:credit_transaction, user: user, amount: 300)

        # Spend 50 credits (balance goes from 300 to 250, still below 500)
        create(:credit_transaction, user: user, amount: -50)

        expect(SendPushNotificationJob).not_to have_received(:perform_later)
      end

      it "respects 24h cache to avoid spam" do
        # Start with 600 credits
        create(:credit_transaction, user: user, amount: 600)

        # First transaction that drops below 500
        create(:credit_transaction, user: user, amount: -200)
        expect(SendPushNotificationJob).to have_received(:perform_later).once

        # Reset mock
        allow(SendPushNotificationJob).to receive(:perform_later)

        # Simulate cache hit (notification sent less than 24h ago)
        allow(Rails.cache).to receive(:read).with("low_credits_notification:#{user.id}").and_return(1.hour.ago)

        # Another transaction that keeps balance below 500
        create(:credit_transaction, user: user, amount: -50)

        # Should not send another notification
        expect(SendPushNotificationJob).not_to have_received(:perform_later)
      end
    end

    context "when balance increases above 500" do
      it "does not send notification" do
        # Start with 400 credits
        create(:credit_transaction, user: user, amount: 400)

        # Add 200 credits (balance goes from 400 to 600)
        create(:credit_transaction, user: user, amount: 200)

        expect(SendPushNotificationJob).not_to have_received(:perform_later)
      end
    end
  end
end
