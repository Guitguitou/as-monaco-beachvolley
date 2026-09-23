# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::WeeklyNotice do
  let(:secondary) { Registrations::WeeklyPriorityRule::SECONDARY }
  let(:training) { build(:session) }

  def notice(status: nil, rank: secondary, session: training)
    registration = status && build(:registration, status: status)
    described_class.new(session: session, rank: rank, registration: registration)
  end

  it "flags a training that would be the player's second of the week" do
    expect(notice.secondary?).to be(true)
    expect(notice.badge_label).to eq("2e entraînement")
    expect(notice.message).to start_with("Ce serait ton 2e entraînement de la semaine")
  end

  it "warns a registered player they can be moved to the waitlist" do
    expect(notice(status: :confirmed).badge_label).to eq("Non prioritaire")
    expect(notice(status: :confirmed).message).to include("tu repasses en liste d'attente (crédits rendus)")
    expect(notice(status: :waitlisted).message).to include("tu passes après les joueurs qui n'en ont pas encore")
  end

  it "says nothing for a first training or another type of session" do
    expect(notice(rank: nil).secondary?).to be(false)
    expect(notice(rank: nil).message).to be_nil
    expect(notice(session: build(:session, :jeu_libre)).secondary?).to be(false)
  end
end
