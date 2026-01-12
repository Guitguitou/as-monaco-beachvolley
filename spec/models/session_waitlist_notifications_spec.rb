# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session waitlist notifications", type: :model do
  let(:session_record) { create(:session, max_players: 2, price: 400) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  before do
    # Mock VAPID keys
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("test_public_key")
    allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("test_private_key")
    allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:test@example.com")

    # Give users credits
    create(:credit_transaction, user: user1, amount: 1000)
    create(:credit_transaction, user: user2, amount: 1000)
  end

  describe "Règle 1: Passage en liste principale" do
    it "sends notification when user is promoted from waitlist" do
      # Give user3 enough credits to be promoted
      create(:credit_transaction, user: user3, amount: 1000)

      # Fill session
      reg1 = create(:registration, user: user1, session: session_record, status: :confirmed)
      reg2 = create(:registration, user: user2, session: session_record, status: :confirmed)

      # Add user3 to waitlist
      reg3 = create(:registration, user: user3, session: session_record, status: :waitlisted)

      # Mock the job
      allow(SendPushNotificationJob).to receive(:perform_later)

      # Free up a spot and trigger promotion
      reg1.destroy!
      session_record.promote_from_waitlist!

      # Verify notification was sent
      expect(SendPushNotificationJob).to have_received(:perform_later).with(
        user3.id,
        hash_including(
          title: "Tu passes en liste principale !",
          body: include("tu viens de passer en liste principale")
        )
      )
    end
  end

  describe "Règle 2: Pas assez de crédits pour passer en liste principale" do
    it "sends notification when user cannot be promoted due to insufficient credits" do
      # Fill session
      reg1 = create(:registration, user: user1, session: session_record, status: :confirmed)
      reg2 = create(:registration, user: user2, session: session_record, status: :confirmed)

      # Add user3 to waitlist (user3 has only 100 credits, session costs 400)
      reg3 = create(:registration, user: user3, session: session_record, status: :waitlisted)

      # Mock the job
      allow(SendPushNotificationJob).to receive(:perform_later)

      # Free up a spot and trigger promotion attempt
      reg1.destroy!
      session_record.promote_from_waitlist!

      # Verify notification was sent
      expect(SendPushNotificationJob).to have_received(:perform_later).with(
        user3.id,
        hash_including(
          title: "Pas assez de crédits",
          body: "Tu n'as pas assez de crédits pour passer en liste principale."
        )
      )
    end
  end
end
