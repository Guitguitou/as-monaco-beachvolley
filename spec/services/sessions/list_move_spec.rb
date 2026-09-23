# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ListMove do
  let(:session_record) { create(:session, max_players: 12) }
  let(:player) { create(:user) }
  let(:move) { described_class.new(session_record) }

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    create(:credit_transaction, user: player, amount: 1000)
  end

  it "confirms a waitlisted player and charges the session" do
    registration = create(:registration, user: player, session: session_record, status: :waitlisted)

    expect { move.confirm(registration) }.to change { player.reload.credit_balance }.by(-session_record.price)
    expect(registration.reload).to be_confirmed
  end

  it "sends a confirmed player back to the waitlist and refunds them" do
    registration = create(:registration, user: player, session: session_record, status: :confirmed)

    expect { move.waitlist(registration) }.to change { player.reload.credit_balance }.by(session_record.price)
    expect(registration.reload).to be_waitlisted
  end

  it "tells whether the player can pay the session" do
    broke = create(:registration, user: create(:user), session: session_record, status: :waitlisted)
    rich = create(:registration, user: player, session: session_record, status: :waitlisted)

    expect([ move.affordable?(broke), move.affordable?(rich) ]).to eq([ false, true ])
  end

  it "moves private coachings without credits" do
    coaching = create(:session, :coaching_prive)
    registration = build(:registration, user: create(:user), session: coaching, status: :waitlisted)

    expect(described_class.new(coaching).affordable?(registration)).to be(true)
  end
end
