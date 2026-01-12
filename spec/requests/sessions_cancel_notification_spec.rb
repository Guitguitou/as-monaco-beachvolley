# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session cancellation notifications", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:session_record) { create(:session, user: coach, title: "Test Session") }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before do
    # Mock VAPID keys
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("test_public_key")
    allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("test_private_key")
    allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:test@example.com")

    # Create registrations
    create(:registration, user: user1, session: session_record, status: :confirmed)
    create(:registration, user: user2, session: session_record, status: :confirmed)

    # Give users credits
    create(:credit_transaction, user: user1, amount: 1000)
    create(:credit_transaction, user: user2, amount: 1000)

    # Mock the job
    allow(SendPushNotificationJob).to receive(:perform_later)

    sign_in coach
  end

  describe "Règle 4: Session annulée" do
    it "sends notification to all registered users when session is cancelled" do
      post "/sessions/#{session_record.id}/cancel"

      expect(response).to redirect_to(sessions_path)
      expect(SendPushNotificationJob).to have_received(:perform_later).with(
        user1.id,
        hash_including(
          title: "Session annulée",
          body: include("est annulée")
        )
      )
      expect(SendPushNotificationJob).to have_received(:perform_later).with(
        user2.id,
        hash_including(
          title: "Session annulée",
          body: include("est annulée")
        )
      )
    end

    it "does not send notification to waitlisted users" do
      waitlisted_user = create(:user)
      create(:registration, user: waitlisted_user, session: session_record, status: :waitlisted)

      post "/sessions/#{session_record.id}/cancel"

      expect(SendPushNotificationJob).not_to have_received(:perform_later).with(
        waitlisted_user.id,
        anything
      )
    end
  end
end
