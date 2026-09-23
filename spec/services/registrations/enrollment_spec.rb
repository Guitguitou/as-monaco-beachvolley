# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registrations::Enrollment do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user) }
  let(:session_record) { create(:session, :jeu_libre, user: coach, start_at: 5.days.from_now.change(hour: 18), end_at: 5.days.from_now.change(hour: 20)) }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  def enroll(session = session_record, waitlist: false, privileged: false)
    described_class.new(user: player, session: session, waitlist: waitlist, privileged: privileged).call
  end

  it "registers the player and charges the session" do
    create(:credit_transaction, user: player, amount: 1000)

    result = nil
    expect { result = enroll }.to change { player.reload.credit_balance }.by(-session_record.price)

    expect(result).to have_attributes(success?: true, message: "Inscription réussie ✅")
  end

  it "puts the player on the waitlist without charging when asked" do
    create(:credit_transaction, user: player, amount: 1000)

    result = nil
    expect { result = enroll(waitlist: true) }.not_to change { player.reload.credit_balance }

    expect(result.message).to eq("Ajout en liste d'attente ✅")
  end

  it "explains why the registration is refused" do
    result = enroll

    expect(result.success?).to be(false)
    expect(result.message).to be_present
    expect(session_record.registrations).to be_empty
  end

  it "lets a privileged user add someone to a private coaching" do
    coaching = create(:session, :coaching_prive, user: coach, start_at: 6.days.from_now.change(hour: 10), end_at: 6.days.from_now.change(hour: 11))

    expect(enroll(coaching).success?).to be(false)
    expect(enroll(coaching, privileged: true).success?).to be(true)
  end
end
