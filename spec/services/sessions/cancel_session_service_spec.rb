require "rails_helper"

RSpec.describe Sessions::CancelSessionService do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:session_record) { create(:session, user: coach, title: "Test", max_players: 12) }
  let(:player) { create(:user, activated_at: Time.current) }
  let(:waitlisted) { create(:user, activated_at: Time.current) }

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    create(:credit_transaction, user: player, amount: 1000)
    create(:credit_transaction, user: waitlisted, amount: 1000)
    create(:registration, user: player, session: session_record, status: :confirmed)
    create(:registration, user: waitlisted, session: session_record, status: :waitlisted)
  end

  it "destroys the session" do
    expect {
      described_class.call(session: session_record)
    }.to change(Session, :count).by(-1)
  end

  it "refunds confirmed participants" do
    expect {
      described_class.call(session: session_record)
    }.to change { player.reload.credit_balance }.by(session_record.price)
  end

  it "does not refund waitlisted participants" do
    expect {
      described_class.call(session: session_record)
    }.not_to change { waitlisted.reload.credit_balance }
  end

  it "notifies confirmed participants" do
    described_class.call(session: session_record)

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      player.id, hash_including(title: "Session annulée")
    )
    expect(SendPushNotificationJob).not_to have_received(:perform_later).with(
      waitlisted.id, anything
    )
  end
end
