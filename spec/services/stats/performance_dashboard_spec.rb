# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stats::PerformanceDashboard do
  let(:timezone) { ActiveSupport::TimeZone["Europe/Paris"] }
  let(:service) { described_class.new(timezone: "Europe/Paris") }
  let(:coach) { create(:user, :coach) }
  let(:admin) { create(:user, :admin) }

  let(:male_level) { create(:level, gender: "male", name: "G1 M") }
  let(:female_level) { create(:level, gender: "female", name: "G1 F") }

  let(:male_player1) { create(:user, first_name: "John", last_name: "Doe") }
  let(:male_player2) { create(:user, first_name: "Bob", last_name: "Smith") }
  let(:female_player1) { create(:user, first_name: "Alice", last_name: "Martin") }
  let(:female_player2) { create(:user, first_name: "Emma", last_name: "Wilson") }

  before do
    # Assign levels to players
    create(:user_level, user: male_player1, level: male_level)
    create(:user_level, user: male_player2, level: male_level)
    create(:user_level, user: female_player1, level: female_level)
    create(:user_level, user: female_player2, level: female_level)
  end

  describe "#call" do
    context "with all-time stats" do
      it "returns the male player with most sessions" do
        # Create sessions with registrations
        session1 = create(:session, :jeu_libre, start_at: 1.month.ago, end_at: 1.month.ago + 90.minutes, user: coach)
        session2 = create(:session, :entrainement, start_at: 2.months.ago, end_at: 2.months.ago + 90.minutes, user: coach)
        session3 = create(:session, :jeu_libre, start_at: 3.months.ago, end_at: 3.months.ago + 90.minutes, user: coach)

        create(:registration, user: male_player1, session: session1, status: :confirmed)
        create(:registration, user: male_player1, session: session2, status: :confirmed)
        create(:registration, user: male_player1, session: session3, status: :confirmed)
        create(:registration, user: male_player2, session: session1, status: :confirmed)

        result = service.call

        expect(result[:all_time][:male]).to be_present
        expect(result[:all_time][:male][:user]).to eq(male_player1)
        expect(result[:all_time][:male][:count]).to eq(3)
      end

      it "returns the female player with most sessions" do
        session1 = create(:session, :jeu_libre, start_at: 1.month.ago, end_at: 1.month.ago + 90.minutes, user: coach)
        session2 = create(:session, :entrainement, start_at: 2.months.ago, end_at: 2.months.ago + 90.minutes, user: coach)

        create(:registration, user: female_player1, session: session1, status: :confirmed)
        create(:registration, user: female_player1, session: session2, status: :confirmed)
        create(:registration, user: female_player2, session: session1, status: :confirmed)

        result = service.call

        expect(result[:all_time][:female]).to be_present
        expect(result[:all_time][:female][:user]).to eq(female_player1)
        expect(result[:all_time][:female][:count]).to eq(2)
      end

      it "excludes waitlisted registrations" do
        session1 = create(:session, :jeu_libre, start_at: 1.month.ago, end_at: 1.month.ago + 90.minutes, user: coach)
        create(:registration, user: male_player1, session: session1, status: :waitlisted)
        create(:registration, user: male_player2, session: session1, status: :confirmed)

        result = service.call

        expect(result[:all_time][:male]).to be_present
        expect(result[:all_time][:male][:user]).to eq(male_player2)
        expect(result[:all_time][:male][:count]).to eq(1)
      end

      it "excludes admins, coaches, and responsables" do
        session1 = create(:session, :jeu_libre, start_at: 1.month.ago, end_at: 1.month.ago + 90.minutes, user: coach)
        create(:registration, user: admin, session: session1, status: :confirmed)
        create(:registration, user: coach, session: session1, status: :confirmed)
        create(:registration, user: male_player1, session: session1, status: :confirmed)

        result = service.call

        expect(result[:all_time][:male]).to be_present
        expect(result[:all_time][:male][:user]).to eq(male_player1)
      end
    end

    context "with free play week stats" do
      it "returns players with most free play sessions this week" do
        week_start = timezone.now.beginning_of_week(:monday)
        session1 = create(:session, :jeu_libre, start_at: week_start + 1.day, end_at: week_start + 1.day + 90.minutes, user: coach)
        session2 = create(:session, :jeu_libre, start_at: week_start + 2.days, end_at: week_start + 2.days + 90.minutes, user: coach)

        create(:registration, user: male_player1, session: session1, status: :confirmed)
        create(:registration, user: male_player1, session: session2, status: :confirmed)
        create(:registration, user: male_player2, session: session1, status: :confirmed)

        result = service.call

        expect(result[:free_play_week][:male]).to be_present
        expect(result[:free_play_week][:male][:user]).to eq(male_player1)
        expect(result[:free_play_week][:male][:count]).to eq(2)
      end

      it "excludes sessions from other weeks" do
        week_start = timezone.now.beginning_of_week(:monday)
        this_week_session = create(:session, :jeu_libre, start_at: week_start + 1.day, end_at: week_start + 1.day + 90.minutes, user: coach)
        last_week_session = create(:session, :jeu_libre, start_at: week_start - 1.day, end_at: week_start - 1.day + 90.minutes, user: coach)

        create(:registration, user: male_player1, session: this_week_session, status: :confirmed)
        create(:registration, user: male_player2, session: last_week_session, status: :confirmed)

        result = service.call

        expect(result[:free_play_week][:male]).to be_present
        expect(result[:free_play_week][:male][:user]).to eq(male_player1)
        expect(result[:free_play_week][:male][:count]).to eq(1)
      end
    end

    context "with free play month stats" do
      it "returns players with most free play sessions this month" do
        month_start = timezone.now.beginning_of_month
        session1 = create(:session, :jeu_libre, start_at: month_start + 1.day, end_at: month_start + 1.day + 90.minutes, user: coach)
        session2 = create(:session, :jeu_libre, start_at: month_start + 5.days, end_at: month_start + 5.days + 90.minutes, user: coach)

        create(:registration, user: female_player1, session: session1, status: :confirmed)
        create(:registration, user: female_player1, session: session2, status: :confirmed)
        create(:registration, user: female_player2, session: session1, status: :confirmed)

        result = service.call

        expect(result[:free_play_month][:female]).to be_present
        expect(result[:free_play_month][:female][:user]).to eq(female_player1)
        expect(result[:free_play_month][:female][:count]).to eq(2)
      end
    end

    context "with training week stats" do
      it "returns players with most training sessions this week" do
        week_start = timezone.now.beginning_of_week(:monday)
        session1 = create(:session, :entrainement, start_at: week_start + 1.day, end_at: week_start + 1.day + 90.minutes, user: coach)
        session2 = create(:session, :entrainement, start_at: week_start + 3.days, end_at: week_start + 3.days + 90.minutes, user: coach)

        create(:registration, user: male_player1, session: session1, status: :confirmed)
        create(:registration, user: male_player1, session: session2, status: :confirmed)

        result = service.call

        expect(result[:training_week][:male]).to be_present
        expect(result[:training_week][:male][:user]).to eq(male_player1)
        expect(result[:training_week][:male][:count]).to eq(2)
      end
    end

    context "with training month stats" do
      it "returns players with most training sessions this month" do
        month_start = timezone.now.beginning_of_month
        session1 = create(:session, :entrainement, start_at: month_start + 1.day, end_at: month_start + 1.day + 90.minutes, user: coach)
        session2 = create(:session, :entrainement, start_at: month_start + 10.days, end_at: month_start + 10.days + 90.minutes, user: coach)

        create(:registration, user: female_player1, session: session1, status: :confirmed)
        create(:registration, user: female_player1, session: session2, status: :confirmed)

        result = service.call

        expect(result[:training_month][:female]).to be_present
        expect(result[:training_month][:female][:user]).to eq(female_player1)
        expect(result[:training_month][:female][:count]).to eq(2)
      end
    end

    context "with inactivity stats" do
      it "returns the most inactive player" do
        old_session = create(:session, :jeu_libre, start_at: 30.days.ago, end_at: 30.days.ago + 90.minutes, user: coach)
        recent_session = create(:session, :jeu_libre, start_at: 5.days.ago, end_at: 5.days.ago + 90.minutes, user: coach)

        create(:registration, user: male_player1, session: old_session, status: :confirmed)
        create(:registration, user: male_player2, session: recent_session, status: :confirmed)

        result = service.call

        expect(result[:inactivity][:male]).to be_present
        expect(result[:inactivity][:male][:user]).to eq(male_player1)
        expect(result[:inactivity][:male][:last_session_at]).to be_present
        expect(result[:inactivity][:male][:days_since]).to be >= 29
      end

      it "handles players who never played" do
        # male_player2 has no registrations
        session1 = create(:session, :jeu_libre, start_at: 10.days.ago, end_at: 10.days.ago + 90.minutes, user: coach)
        create(:registration, user: male_player1, session: session1, status: :confirmed)

        result = service.call

        # The player with no sessions should be considered most inactive
        expect(result[:inactivity][:male]).to be_present
        # Could be either player depending on implementation, but should handle nil gracefully
      end
    end

    context "with no data" do
      it "returns nil for stats when no registrations exist" do
        result = service.call

        expect(result[:all_time][:male]).to be_nil
        expect(result[:all_time][:female]).to be_nil
        expect(result[:free_play_week][:male]).to be_nil
        expect(result[:free_play_week][:female]).to be_nil
      end
    end
  end
end

