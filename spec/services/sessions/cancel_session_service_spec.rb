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

  it "keeps the session, marked as cancelled with its reason" do
    expect {
      described_class.call(session: session_record, reason: "meteo")
    }.not_to change(Session, :count)

    expect(session_record.reload).to be_cancelled
    expect(session_record.cancellation_reason).to eq("meteo")
  end

  it "rejects an unknown reason" do
    expect {
      described_class.call(session: session_record, reason: "flemme")
    }.to raise_error(ArgumentError)
    expect(session_record.reload).not_to be_cancelled
  end

  it "refunds confirmed participants" do
    expect {
      described_class.call(session: session_record, reason: "meteo")
    }.to change { player.reload.credit_balance }.by(session_record.price)
  end

  it "does not refund waitlisted participants" do
    expect {
      described_class.call(session: session_record, reason: "meteo")
    }.not_to change { waitlisted.reload.credit_balance }
  end

  it "excuses the late cancellations of the session" do
    late = LateCancellation.create!(user: waitlisted, session: session_record)

    described_class.call(session: session_record, reason: "meteo")

    expect(late.reload).to be_excused
  end

  it "notifies confirmed participants" do
    described_class.call(session: session_record, reason: "meteo")

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      player.id, hash_including(title: "Session annulée")
    )
    expect(SendPushNotificationJob).not_to have_received(:perform_later).with(
      waitlisted.id, anything
    )
  end

  it "refunds the coach who paid for a private coaching" do
    coaching = create(:session, :coaching_prive, user: coach, start_at: 4.days.from_now, end_at: 4.days.from_now + 1.hour)

    expect {
      described_class.call(session: coaching, reason: "absence_encadrant")
    }.to change { coach.reload.credit_balance }.by(ClubRules.current.price_for("coaching_prive"))
  end
end
