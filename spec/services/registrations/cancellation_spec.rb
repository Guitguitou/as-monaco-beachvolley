# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registrations::Cancellation do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user) }

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    create(:credit_transaction, user: player, amount: 1000)
  end

  def register(session)
    create(:registration, user: player, session: session, status: :confirmed)
  end

  it "unregisters and refunds before the deadline" do
    session = create(:session, user: coach, start_at: 5.days.from_now.change(hour: 18), end_at: 5.days.from_now.change(hour: 20))
    registration = register(session)

    message = nil
    expect { message = described_class.new(registration).call }.to change { player.reload.credit_balance }.by(session.price)

    expect(message).to eq("Désinscription réussie ✅")
    expect(Registration.exists?(registration.id)).to be(false)
  end

  it "keeps the credits and records a late cancellation past the training deadline" do
    start_at = 1.day.from_now.change(hour: 18)
    session = create(:session, user: coach, start_at: start_at, end_at: start_at + 2.hours, cancellation_deadline_at: 1.hour.ago)
    registration = register(session)

    message = nil
    expect { message = described_class.new(registration).call }.not_to change { player.reload.credit_balance }

    expect(message).to eq("Désinscription réussie, mais délai dépassé — pas de remboursement.")
    expect(LateCancellation.where(user: player, session: session)).to exist
  end

  it "never refunds a session that has started" do
    session = create(:session, :jeu_libre, user: coach, start_at: 2.days.from_now, end_at: 2.days.from_now + 90.minutes)
    registration = register(session)
    session.update_columns(start_at: 1.hour.ago, end_at: 1.hour.from_now)

    expect(described_class.new(registration.reload).call).to eq("Désinscription réussie, mais la session a déjà eu lieu — pas de remboursement.")
    expect(LateCancellation.count).to eq(0)
  end

  it "gives the freed spot to the waitlist" do
    session = create(:session, user: coach, max_players: 1, start_at: 5.days.from_now.change(hour: 18), end_at: 5.days.from_now.change(hour: 20))
    registration = register(session)
    waiting = create(:user)
    create(:credit_transaction, user: waiting, amount: 1000)
    create(:registration, user: waiting, session: session, status: :waitlisted)

    described_class.new(registration).call

    expect(session.registrations.find_by(user: waiting)).to be_confirmed
  end
end
