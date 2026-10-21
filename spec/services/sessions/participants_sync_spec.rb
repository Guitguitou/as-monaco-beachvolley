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

  context "when a participant is removed after the training cancellation deadline" do
    let(:training) do
      create(:session, user: coach, start_at: 1.day.from_now.change(hour: 18), end_at: 1.day.from_now.change(hour: 20))
    end
    let(:training_sync) { described_class.new(session: training, allow_private_coaching: false) }

    before do
      training_sync.call([ player.id ])
      training.update_columns(cancellation_deadline_at: 1.hour.ago)
    end

    it "applies the late unregistration" do
      expect { training_sync.call([]) }.not_to change { player.reload.credit_balance }
      expect(LateCancellation.where(user: player, session: training)).to exist
    end

    it "refunds the participants the staff excused" do
      expect { training_sync.call([], excused_ids: [ player.id.to_s ]) }.to change { player.reload.credit_balance }.by(training.price)
      expect(LateCancellation.counted).to be_empty
    end
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
