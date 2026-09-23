# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ParticipantsSync do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:session_record) { create(:session, :jeu_libre, user: coach) }
  let(:player) { create(:user, first_name: "John", last_name: "Doe", activated_at: Time.current) }
  let(:sync) { described_class.new(session: session_record, allow_private_coaching: false) }

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    create(:credit_transaction, user: player, amount: 1000)
  end

  it "registers the new participants and debits their credits" do
    expect { sync.call([ player.id.to_s, "" ]) }.to change { player.reload.credit_balance }.by(-session_record.price)

    expect(session_record.registrations.find_by(user: player)).to be_confirmed
  end

  it "unregisters the removed participants and refunds them" do
    sync.call([ player.id ])

    expect { sync.call([]) }.to change { player.reload.credit_balance }.by(session_record.price)
    expect(session_record.registrations.where(user: player)).to be_empty
  end

  it "reports the participants it could not register" do
    broke = create(:user, first_name: "Paul", last_name: "Broke", activated_at: Time.current)

    errors = sync.call([ broke.id ])

    expect(errors).to contain_exactly(start_with("Paul Broke: "))
    expect(session_record.registrations.where(user: broke)).to be_empty
  end

  it "registers on a private coaching only when allowed" do
    coaching = create(:session, :coaching_prive, user: coach)

    expect(described_class.new(session: coaching, allow_private_coaching: false).call([ player.id ])).not_to be_empty
    expect(described_class.new(session: coaching, allow_private_coaching: true).call([ player.id ])).to be_empty
  end
end
