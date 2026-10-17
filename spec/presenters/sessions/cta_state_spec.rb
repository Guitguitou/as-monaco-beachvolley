# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CtaState do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user) }
  let(:start_at) { 3.days.from_now.change(hour: 19) }
  let(:session) { create(:session, :jeu_libre, user: coach, start_at: start_at, end_at: start_at + 90.minutes, max_players: 2) }
  let(:state) { described_class.new(session: session, user: player) }

  def credit(user, amount)
    create(:credit_transaction, user: user, amount: amount)
  end

  it "is open with the cost and the balance left" do
    credit(player, session.price + 200)

    expect(state.kind).to eq(:open)
    expect(state.balance_after).to eq(200)
  end

  it "asks for credits when the balance is short" do
    credit(player, session.price - 60)

    expect(state.kind).to eq(:no_credits)
    expect(state.missing_credits).to eq(60)
  end

  it "offers the waitlist with the estimated position when full" do
    credit(player, session.price + 200)
    2.times { create(:registration, user: create(:user), session: session, status: :confirmed) }
    create(:registration, user: create(:user), session: session, status: :waitlisted)

    expect(state.kind).to eq(:waitlist)
    expect(state.waitlist_position).to eq(2)
  end

  it "points to the levels when the training is not for the player" do
    training = create(:session, :entrainement, user: coach, start_at: start_at + 1.day, end_at: start_at + 1.day + 2.hours)
    training.levels << create(:level)

    expect(described_class.new(session: training, user: player).kind).to eq(:wrong_level)
  end

  it "counts down to the opening of a training" do
    training = create(:session, :entrainement, user: coach, start_at: start_at + 1.day, end_at: start_at + 1.day + 2.hours,
                                               registration_opens_at: 1.day.from_now)
    cta = described_class.new(session: training, user: player)

    expect(cta.kind).to eq(:not_yet_open)
    expect(cta.opens_at).to eq(training.registration_opens_at)
  end

  it "knows whether unsubscribing refunds the credit" do
    credit(player, session.price + 200)
    create(:registration, user: player, session: session, status: :confirmed)

    expect(state.kind).to eq(:registered)
    expect(state).to be_refundable_now
  end
end
