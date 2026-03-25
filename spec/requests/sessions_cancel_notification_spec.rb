# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session cancellation notifications", type: :request do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:session_record) { create(:session, user: coach, title: "Test Session") }
  let(:user1) { create(:user, activated_at: Time.current) }
  let(:user2) { create(:user, activated_at: Time.current) }

  before do
    travel_to(Time.zone.parse("2025-06-10 10:00"))

    # Mock VAPID keys
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("test_public_key")
    allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("test_private_key")
    allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:test@example.com")

    # Credits before registrations (validations)
    create(:credit_transaction, user: user1, amount: 1000)
    create(:credit_transaction, user: user2, amount: 1000)

    create(:registration, user: user1, session: session_record, status: :confirmed)
    create(:registration, user: user2, session: session_record, status: :confirmed)

    # Mock the job
    allow(SendPushNotificationJob).to receive(:perform_later)

    sign_in coach
  end

  after do
    travel_back
  end

  describe "Règle 4: Session annulée" do
    it "sends notification to all registered users when session is cancelled" do
      post "/sessions/#{session_record.id}/cancel"

      expect(response).to redirect_to(sessions_path(date: session_record.start_at.strftime("%Y-%m-%d")))
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
      waitlisted_user = create(:user, activated_at: Time.current)
      create(:credit_transaction, user: waitlisted_user, amount: 1000)
      create(:registration, user: waitlisted_user, session: session_record, status: :waitlisted)

      post "/sessions/#{session_record.id}/cancel"

      expect(SendPushNotificationJob).not_to have_received(:perform_later).with(
        waitlisted_user.id,
        anything
      )
    end
  end
end
