require "rails_helper"

RSpec.describe Sessions::MergeService do
  let(:start_at) { 2.days.from_now.change(hour: 18, min: 0) }
  let(:g1) { create(:level, name: "G1m") }
  let(:g2) { create(:level, name: "G2m") }
  let(:coach_kept) { create(:user, :coach, activated_at: Time.current) }
  let(:coach_absorbed) { create(:user, :coach, activated_at: Time.current) }
  let!(:kept) do
    create(:session, user: coach_kept, start_at:, end_at: start_at + 90.minutes, max_players: 4,
                     levels: [ g1 ], coach_notes: "Notes G1")
  end
  let!(:absorbed) do
    create(:session, :terrain_2, user: coach_absorbed, start_at:, end_at: start_at + 90.minutes, max_players: 4,
                                 levels: [ g2 ], coach_notes: "Notes G2")
  end

  def player_in(level)
    create(:user, activated_at: Time.current, levels: [ level ]).tap do |user|
      create(:credit_transaction, user:, amount: 1000)
    end
  end

  def merge(coach: coach_absorbed, max_players: 8)
    described_class.call(kept:, absorbed:, coach:, max_players:)
  end

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
  end

  it "moves players, levels and waitlist into the kept session" do
    p1 = player_in(g1)
    p2 = player_in(g2)
    waiting = player_in(g2)
    create(:registration, user: p1, session: kept)
    create(:registration, user: p2, session: absorbed)
    create(:registration, user: waiting, session: absorbed, status: :waitlisted)

    merge

    kept.reload
    expect(kept.participants).to contain_exactly(p1, p2, waiting)
    expect(kept.levels).to contain_exactly(g1, g2)
    expect(kept.registrations.find_by(user: waiting)).to be_confirmed
  end

  it "applies the chosen coach, the new capacity and appends coach notes" do
    merge(coach: coach_absorbed, max_players: 6)

    kept.reload
    expect(kept.user).to eq(coach_absorbed)
    expect(kept.max_players).to eq(6)
    expect(kept.coach_notes).to eq("Notes G1\n\nNotes G2")
    expect(kept.title).to eq(kept.title)
  end

  it "cancels the absorbed session as merged without refunding transferred players" do
    p2 = player_in(g2)
    create(:registration, user: p2, session: absorbed)

    expect { merge }.not_to change { p2.reload.credit_balance }

    absorbed.reload
    expect(absorbed).to be_cancelled
    expect(absorbed.cancellation_reason).to eq("fusionnee")
    expect(absorbed.registrations).to be_empty
  end

  it "keeps a single registration for a player in both sessions and refunds the absorbed one" do
    both = create(:user, activated_at: Time.current, levels: [ g1, g2 ])
    create(:credit_transaction, user: both, amount: 1000)
    create(:registration, user: both, session: kept)
    # Créneau identique : seule une saisie admin peut produire ce doublon.
    build(:registration, user: both, session: absorbed).save!(validate: false)
    TransactionService.new(both, absorbed, absorbed.price).create_transaction

    expect { merge }.to change { both.reload.credit_balance }.by(absorbed.price)
    expect(kept.registrations.where(user: both).count).to eq(1)
  end

  it "does not excuse the late cancellations of the absorbed session" do
    late = LateCancellation.create!(user: player_in(g2), session: absorbed)

    merge

    expect(late.reload).not_to be_excused
  end

  it "notifies transferred players and the released coach" do
    p2 = player_in(g2)
    create(:registration, user: p2, session: absorbed)

    expect { merge(coach: coach_absorbed) }
      .to have_enqueued_mail(SessionMailer, :session_merged).with(p2, kept)
      .and have_enqueued_mail(SessionMailer, :coach_released)
  end

  describe "refusals" do
    it "refuses a capacity below the confirmed players" do
      2.times { create(:registration, user: player_in(g1), session: kept) }
      create(:registration, user: player_in(g2), session: absorbed)

      expect { merge(max_players: 2) }.to raise_error(Sessions::MergeService::Error, /capacité/i)
      expect(absorbed.reload).not_to be_cancelled
    end

    it "refuses sessions on different time slots" do
      absorbed.update!(start_at: start_at + 30.minutes, end_at: start_at + 2.hours)

      expect { merge }.to raise_error(Sessions::MergeService::Error, /créneau/i)
    end

    it "refuses different prices" do
      absorbed.update_column(:price, kept.price + 1)

      expect { merge }.to raise_error(Sessions::MergeService::Error, /prix/i)
    end

    it "refuses non-training sessions" do
      absorbed.update_column(:session_type, "jeu_libre")

      expect { merge }.to raise_error(Sessions::MergeService::Error, /entraînement/i)
    end

    it "refuses a cancelled session" do
      absorbed.update_column(:cancelled_at, Time.current)

      expect { merge }.to raise_error(Sessions::MergeService::Error, /annulée/i)
    end

    it "refuses merging a session into itself" do
      expect { described_class.call(kept:, absorbed: kept, coach: coach_kept, max_players: 8) }
        .to raise_error(Sessions::MergeService::Error)
    end
  end
end
