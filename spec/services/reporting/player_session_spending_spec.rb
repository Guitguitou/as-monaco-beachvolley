# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::PlayerSessionSpending do
  let(:alice) { create(:user, first_name: "Alice") }
  let(:bob) { create(:user, first_name: "Bob") }
  let(:training) { create(:session) }
  let(:other_training) { create(:session) }
  let(:free_play) { create(:session, :jeu_libre) }
  let(:range) { 1.day.ago..1.month.from_now }
  let(:now) { 1.month.from_now }

  def pay(user, session, credits, type: :training_payment)
    create(:credit_transaction, user: user, session: session, transaction_type: type, amount: -credits)
  end

  def refund(user, session, credits)
    create(:credit_transaction, user: user, session: session, transaction_type: :refund, amount: credits)
  end

  subject(:spending) { described_class.new(range, now: now) }

  before do
    pay(alice, training, 800)
    pay(alice, other_training, 800)
    pay(alice, free_play, 500, type: :free_play_payment)
    pay(bob, training, 800)
  end

  it "counts sessions and euros per player and session type" do
    alice_row = spending.rows.find { |row| row.user == alice }

    expect(alice_row.by_type["entrainement"]).to eq(described_class::Stat.new(count: 2, amount: 16.0))
    expect(alice_row.by_type["jeu_libre"]).to eq(described_class::Stat.new(count: 1, amount: 5.0))
    expect(alice_row.total).to eq(described_class::Stat.new(count: 3, amount: 21.0))
  end

  it "sorts players by amount paid, highest first" do
    expect(spending.rows.map(&:user)).to eq([ alice, bob ])
  end

  it "drops sessions that were refunded" do
    refund(bob, training, 800)

    expect(spending.rows.map(&:user)).to eq([ alice ])
  end

  it "ignores sessions that have not happened yet" do
    spending = described_class.new(range, now: 1.hour.ago)

    expect(spending.rows).to be_empty
  end

  it "sums each session type across players" do
    expect(spending.session_types).to eq(%w[entrainement jeu_libre])
    expect(spending.totals["entrainement"]).to eq(described_class::Stat.new(count: 3, amount: 24.0))
  end
end
