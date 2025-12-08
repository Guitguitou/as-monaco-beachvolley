# frozen_string_literal: true

require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    subject(:session) { create(:session) }

    it "belongs to user" do
      expect(session).to respond_to(:user)
      expect(session.user).to be_a(User)
    end

    it "has many session_levels" do
      expect(session).to respond_to(:session_levels)
    end

    it "has many levels through session_levels" do
      expect(session).to respond_to(:levels)
    end

    it "has many registrations" do
      expect(session).to respond_to(:registrations)
    end

    it "has many participants through registrations" do
      expect(session).to respond_to(:participants)
    end
  end

  describe "validations" do
    it "requires title" do
      session = build(:session, title: nil)
      expect(session).not_to be_valid
      expect(session.errors[:title]).to be_present
    end

    it "requires start_at" do
      session = build(:session, start_at: nil)
      expect(session).not_to be_valid
      expect(session.errors[:start_at]).to be_present
    end

    it "requires end_at" do
      session = build(:session, end_at: nil)
      expect(session).not_to be_valid
      expect(session.errors[:end_at]).to be_present
    end

    it "requires session_type" do
      session = build(:session, session_type: nil)
      expect(session).not_to be_valid
      expect(session.errors[:session_type]).to be_present
    end

    it "requires terrain" do
      session = build(:session, terrain: nil)
      expect(session).not_to be_valid
      expect(session.errors[:terrain]).to be_present
    end

    it "validates end_at is after start_at" do
      session = build(:session, start_at: Time.current, end_at: Time.current - 1.hour)
      expect(session).not_to be_valid
      expect(session.errors[:end_at]).to be_present
    end
  end

  describe "callbacks" do
    describe "before_validation :set_price_from_type" do
      it "sets price from session type" do
        session = build(:session, session_type: "entrainement", price: nil)
        session.valid?
        expect(session.price).to eq(Session::TRAINING_PRICE)
      end
    end
  end

  describe "#full?" do
    let(:future_time) { Time.current + 2.days }

    context "when max_players is not set" do
      subject(:session) { create(:session, max_players: nil) }

      it "returns false" do
        expect(session).not_to be_full
      end
    end

    context "when max_players is set" do
      subject(:session) { create(:session, max_players: 2, start_at: future_time, end_at: future_time + 1.5.hours) }
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }

      before do
        create(:credit_transaction, user: user1, amount: 10_000)
        create(:credit_transaction, user: user2, amount: 10_000)
      end

      context "when confirmed registrations < max_players" do
        before { create(:registration, session: session, user: user1, status: :confirmed, allow_deadline_bypass: true) }

        it "returns false" do
          expect(session).not_to be_full
        end
      end

      context "when confirmed registrations = max_players" do
        before do
          create(:registration, session: session, user: user1, status: :confirmed, allow_deadline_bypass: true)
          create(:registration, session: session, user: user2, status: :confirmed, allow_deadline_bypass: true)
        end

        it "returns true" do
          expect(session).to be_full
        end
      end
    end
  end

  describe "#display_name" do
    context "when session_type is entrainement" do
      let(:level) { create(:level, name: "A", gender: "male") }
      subject(:session) { create(:session, session_type: "entrainement", title: "Training", levels: [level]) }

      it "includes title and levels" do
        expect(session.display_name).to include("Training")
        expect(session.display_name).to include("A M")
      end
    end

    context "when session_type is jeu_libre" do
      subject(:session) { create(:session, session_type: "jeu_libre", title: "Free Play") }

      it "returns only title" do
        expect(session.display_name).to eq("Free Play")
      end
    end
  end

  describe "#registration_open_state_for" do
    let(:user) { create(:user) }
    let(:future_time) { Time.current + 2.days }

    context "when session is not entrainement" do
      let(:session) { create(:session, session_type: "jeu_libre", start_at: future_time, end_at: future_time + 1.5.hours) }

      it "returns [true, nil]" do
        open, reason = session.registration_open_state_for(user)
        expect(open).to be true
        expect(reason).to be_nil
      end
    end

    context "when registration_opens_at is not set" do
      let(:session) do
        create(:session, session_type: "entrainement", registration_opens_at: nil,
                         start_at: future_time, end_at: future_time + 1.5.hours)
      end

      it "returns [true, nil]" do
        open, reason = session.registration_open_state_for(user)
        expect(open).to be true
        expect(reason).to be_nil
      end
    end
  end

  describe "#past_registration_deadline?" do
    let(:start_at) { Time.current + 1.day }
    let(:session) { create(:session, start_at: start_at, end_at: start_at + 1.5.hours) }

    context "when current time is before 17h on session day" do
      around do |example|
        travel_to start_at.change(hour: 16, min: 0) do
          example.run
        end
      end

      it "returns false" do
        expect(session.past_registration_deadline?).to be false
      end
    end

    context "when current time is after 17h on session day" do
      around do |example|
        travel_to start_at.change(hour: 18, min: 0) do
          example.run
        end
      end

      it "returns true" do
        expect(session.past_registration_deadline?).to be true
      end
    end
  end

  describe "scopes" do
    let(:coach) { create(:user, coach: true) }
    let(:current_time) { Time.zone.now }
    let(:week_start) { current_time.beginning_of_week }
    let(:month_start) { current_time.beginning_of_month }
    let(:year_start) { current_time.beginning_of_year }

    before do
      coach.balance.update!(amount: 2000)
    end

    let!(:upcoming_training) do
      create(:session, session_type: "entrainement", start_at: current_time + 1.day + 10.hours,
                      end_at: current_time + 1.day + 12.hours, user: coach)
    end
    let!(:past_training) do
      create(:session, session_type: "entrainement", start_at: current_time - 1.day + 10.hours,
                      end_at: current_time - 1.day + 12.hours, user: coach, terrain: "Terrain 2")
    end
    let!(:upcoming_free_play) do
      create(:session, session_type: "jeu_libre", start_at: current_time + 1.day + 14.hours,
                       end_at: current_time + 1.day + 16.hours, user: coach, terrain: "Terrain 3")
    end
    let!(:upcoming_private_coaching) do
      create(:session, session_type: "coaching_prive", start_at: current_time + 1.day + 18.hours,
                       end_at: current_time + 1.day + 20.hours, user: coach)
    end
    let!(:week_training) do
      create(:session, session_type: "entrainement", start_at: week_start + 2.days + 10.hours,
                       end_at: week_start + 2.days + 12.hours, user: coach)
    end
    let!(:month_training) do
      create(:session, session_type: "entrainement", start_at: month_start + 20.days + 10.hours,
                       end_at: month_start + 20.days + 12.hours, user: coach, terrain: "Terrain 2")
    end
    let!(:year_training) do
      create(:session, session_type: "entrainement", start_at: year_start + 60.days + 10.hours,
                       end_at: year_start + 60.days + 12.hours, user: coach, terrain: "Terrain 3")
    end

    describe ".upcoming" do
      it "returns sessions starting from now" do
        result = described_class.upcoming
        expect(result).to include(upcoming_training, upcoming_free_play, upcoming_private_coaching)
        expect(result).not_to include(past_training)
      end
    end

    describe ".in_week" do
      it "returns sessions within the specified week" do
        result = described_class.in_week(week_start)
        expect(result).to include(week_training)
        expect(result).not_to include(month_training, year_training)
      end
    end

    describe ".in_month" do
      it "returns sessions within the specified month" do
        result = described_class.in_month(month_start)
        expect(result).to include(month_training, week_training)
        expect(result).not_to include(year_training)
      end
    end

    describe ".in_year" do
      it "returns sessions within the specified year" do
        result = described_class.in_year(year_start)
        expect(result).to include(year_training, month_training, week_training)
      end
    end

    describe ".trainings" do
      it "returns only training sessions" do
        result = described_class.trainings
        expect(result).to include(upcoming_training, past_training, week_training)
        expect(result).not_to include(upcoming_free_play, upcoming_private_coaching)
      end
    end

    describe ".free_plays" do
      it "returns only free play sessions" do
        result = described_class.free_plays
        expect(result).to include(upcoming_free_play)
        expect(result).not_to include(upcoming_training, upcoming_private_coaching)
      end
    end

    describe ".private_coachings" do
      it "returns only private coaching sessions" do
        result = described_class.private_coachings
        expect(result).to include(upcoming_private_coaching)
        expect(result).not_to include(upcoming_training, upcoming_free_play)
      end
    end

    describe ".ordered_by_start" do
      it "orders sessions by start_at" do
        session_1 = create(:session, session_type: "entrainement", start_at: current_time + 3.days + 10.hours,
                           end_at: current_time + 3.days + 12.hours, user: coach, terrain: "Terrain 1")
        session_2 = create(:session, session_type: "entrainement", start_at: current_time + 1.day + 10.hours,
                           end_at: current_time + 1.day + 12.hours, user: coach, terrain: "Terrain 2")
        session_3 = create(:session, session_type: "entrainement", start_at: current_time + 2.days + 10.hours,
                           end_at: current_time + 2.days + 12.hours, user: coach, terrain: "Terrain 3")

        result = described_class.where(id: [session_1.id, session_2.id, session_3.id]).ordered_by_start
        expect(result.to_a).to eq([session_2, session_3, session_1])
      end
    end
  end
end
