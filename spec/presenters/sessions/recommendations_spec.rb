# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::Recommendations do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }
  let(:day) { 3.days.from_now.change(hour: 10) }
  let(:recommendations) { described_class.new(user: player) }

  def free_play(offset, **attrs)
    create(:session, :jeu_libre, user: coach, start_at: day + offset, end_at: day + offset + 1.hour, **attrs)
  end

  it "suggests the next open sessions the player has not joined, up to three" do
    first, second, third, _fourth = (0..3).map { |i| free_play(i * 2.hours) }

    expect(recommendations.sessions).to eq([ first, second, third ])
  end

  it "leaves out joined, full, private and other-level sessions" do
    joined = free_play(0)
    create(:registration, user: player, session: joined, status: :confirmed)
    full = free_play(2.hours, max_players: 1)
    create(:registration, user: create(:user), session: full, status: :confirmed)
    create(:session, :coaching_prive, user: coach, start_at: day + 4.hours, end_at: day + 5.hours)
    create(:session, user: coach, start_at: day + 6.hours, end_at: day + 7.hours, levels: [ create(:level) ])
    open = free_play(8.hours)

    expect(recommendations.sessions).to eq([ open ])
  end

  it "builds the card of a suggested session" do
    session = free_play(0)
    create(:credit_transaction, user: player, amount: 1000)

    state = recommendations.card_state_for(session)

    expect(state.action).to eq(:register)
    expect(state.balance).to eq(1000)
  end
end
