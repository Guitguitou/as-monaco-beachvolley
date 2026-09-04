# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stats::PlayerStats do
  let(:level) { create(:level, name: "G1") }
  let(:user) { create(:user, activated_at: 1.year.ago) }

  subject(:stats) { described_class.new(user: user).call }

  # Les validations d'inscription (crédits, délais, limite hebdo) n'ont pas
  # d'intérêt ici : on veut juste des lignes en base.
  def register(user, session, status: :confirmed)
    registration = Registration.new(user: user, session: session, status: status)
    registration.save!(validate: false)
    registration
  end

  # Une session par créneau : le modèle refuse deux sessions qui se
  # chevauchent sur le même terrain.
  def past_session(type: "entrainement")
    @slot = (@slot || 0) + 1
    start_at = 2.weeks.ago.beginning_of_day + (@slot * 3).hours
    create(:session, session_type: type, start_at: start_at, end_at: start_at + 2.hours)
  end

  describe "sessions played" do
    it "counts only past confirmed sessions, split by type" do
      register(user, past_session(type: "entrainement"))
      register(user, past_session(type: "entrainement"))
      register(user, past_session(type: "jeu_libre"))

      expect(stats.trainings_played).to eq(2)
      expect(stats.free_plays_played).to eq(1)
      expect(stats.sessions_played).to eq(3)
      expect(stats).to be_any_session
    end

    it "ignores upcoming sessions" do
      register(user, create(:session, start_at: 1.week.from_now, end_at: 1.week.from_now + 2.hours))

      expect(stats.sessions_played).to eq(0)
      expect(stats).not_to be_any_session
    end

    it "ignores waitlisted registrations" do
      register(user, past_session, status: :waitlisted)

      expect(stats.sessions_played).to eq(0)
    end

    it "reports the date of the most recent session played" do
      register(user, create(:session, start_at: 3.weeks.ago, end_at: 3.weeks.ago + 2.hours))
      recent = create(:session, start_at: 4.days.ago, end_at: 4.days.ago + 2.hours)
      register(user, recent)

      expect(stats.last_session_at).to be_within(1.second).of(recent.start_at)
    end

    it "returns zeroes for a brand new player" do
      expect(stats.sessions_played).to eq(0)
      expect(stats.last_session_at).to be_nil
      expect(stats.late_cancellations).to eq(0)
    end
  end

  describe "late cancellations" do
    it "counts the player's own late cancellations" do
      create(:late_cancellation, user: user, session: past_session)
      create(:late_cancellation, user: create(:user), session: past_session)

      expect(stats.late_cancellations).to eq(1)
    end
  end

  describe "ranking within the group" do
    let(:teammate) { create(:user) }

    before do
      create(:user_level, user: user, level: level)
      create(:user_level, user: teammate, level: level)
    end

    it "ranks the player against the other members of their level" do
      2.times { register(user, past_session) }
      4.times { register(teammate, past_session) }

      expect(stats.level).to eq(level)
      expect(stats.group_size).to eq(2)
      expect(stats.rank_in_group).to eq(2)
      expect(stats).to be_ranked
    end

    it "puts the most active player first" do
      3.times { register(user, past_session) }
      register(teammate, past_session)

      expect(stats.rank_in_group).to eq(1)
    end

    it "excludes test accounts from the ranking" do
      test_user = create(:user, last_name: "Test")
      create(:user_level, user: test_user, level: level)
      5.times { register(test_user, past_session) }
      register(user, past_session)

      expect(stats.group_size).to eq(1)
      expect(stats.rank_in_group).to eq(1)
    end

    it "reports no rank when the player has no level" do
      user.user_levels.destroy_all

      expect(stats.level).to be_nil
      expect(stats.rank_in_group).to be_nil
      expect(stats.group_size).to eq(0)
      expect(stats).not_to be_ranked
    end

    it "reports no rank when the player has never registered" do
      register(teammate, past_session)

      expect(stats.rank_in_group).to be_nil
    end
  end
end
