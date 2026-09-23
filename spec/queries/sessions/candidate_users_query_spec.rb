# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CandidateUsersQuery do
  let(:coach) { create(:user, :coach) }
  let(:day) { 3.days.from_now.change(hour: 10) }
  let(:session_record) { create(:session, :jeu_libre, user: coach, start_at: day, end_at: day + 90.minutes) }

  def player(first_name, credits: 1000, level: nil)
    create(:user, first_name: first_name, last_name: "Player", level: level).tap do |user|
      create(:credit_transaction, user: user, amount: credits) if credits.positive?
    end
  end

  it "lists the users who can pay and are not registered yet, by name" do
    zoe = player("Zoe")
    anna = player("Anna")
    create(:registration, user: player("Registered"), session: session_record, status: :confirmed)
    player("Broke", credits: 0)

    expect(described_class.call(session: session_record).to_a).to eq([ anna, zoe ])
  end

  it "leaves out the users already confirmed on an overlapping session" do
    busy = player("Busy")
    other = create(:session, :jeu_libre, user: coach, terrain: "Terrain 2", start_at: day + 30.minutes, end_at: day + 2.hours)
    create(:registration, user: busy, session: other, status: :confirmed)

    expect(described_class.call(session: session_record)).not_to include(busy)
  end

  it "keeps the overlapping users when the session is full, since they would be waitlisted" do
    busy = player("Busy")
    other = create(:session, :jeu_libre, user: coach, terrain: "Terrain 2", start_at: day + 30.minutes, end_at: day + 2.hours)
    create(:registration, user: busy, session: other, status: :confirmed)
    session_record.update!(max_players: 1)
    create(:registration, user: player("Full"), session: session_record, status: :confirmed)

    expect(described_class.call(session: session_record)).to include(busy)
  end

  it "keeps only the matching levels for a training restricted to levels" do
    level = create(:level)
    training = create(:session, user: coach, start_at: day, end_at: day + 90.minutes, levels: [ level ])
    matching = player("Matching", level: level)
    player("Other", level: create(:level))

    expect(described_class.call(session: training).to_a).to eq([ matching ])
  end

  it "ignores credits for a private coaching" do
    coaching = create(:session, :coaching_prive, user: coach, start_at: day + 4.hours, end_at: day + 5.hours)
    broke = player("Broke", credits: 0)

    expect(described_class.call(session: coaching)).to include(broke)
  end
end
