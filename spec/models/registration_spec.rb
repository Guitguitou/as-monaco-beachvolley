# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registration, type: :model do
  let(:level) { create(:level) }
  let(:user) { create(:user, level: level) }
  let(:tomorrow_7pm) { (Time.current + 1.day).change(hour: 19, min: 0) }
  let(:session) do
    create(:session, session_type: "entrainement", levels: [ level ], terrain: "Terrain 1",
                     start_at: tomorrow_7pm, end_at: tomorrow_7pm + 1.5.hours)
  end

  before do
    create(:credit_transaction, user: user, amount: 10_000)
  end

  describe "validations" do
    describe "session full validation" do
      context "when session is full" do
        let(:other_user) { create(:user, level: level) }

        before do
          session.update!(max_players: 1)
          create(:credit_transaction, user: other_user, amount: 10_000)
          create(:registration, user: user, session: session)
        end

        it "is invalid" do
          registration = build(:registration, user: other_user, session: session)
          expect(registration).not_to be_valid
          expect(registration.errors[:base]).to include("Session complète.")
        end
      end
    end

    describe "level validation" do
      context "when user level is not allowed" do
        let(:wrong_user) { create(:user, level: create(:level)) }

        before do
          create(:credit_transaction, user: wrong_user, amount: 10_000)
        end

        it "is invalid" do
          registration = build(:registration, user: wrong_user, session: session)
          expect(registration).not_to be_valid
          # Check that there's an error about level (using flexible matching for typographic quotes)
          error_messages = registration.errors[:base].join(" ")
          expect(error_messages).to match(/niveau.*entrainement/i)
        end
      end
    end

    describe "credits validation" do
      context "when user has insufficient credits" do
        before do
          allow_any_instance_of(Balance).to receive(:amount).and_return(0)
        end

        it "is invalid" do
          registration = build(:registration, user: user, session: session)
          expect(registration).not_to be_valid
          expect(registration.errors[:base]).to include("Pas assez de crédits.")
        end
      end
    end

    describe "schedule conflict validation" do
      context "when overlapping with another confirmed session" do
        let(:other_session) do
          create(:session, session_type: "entrainement", levels: [ level ], terrain: "Terrain 2",
                          start_at: tomorrow_7pm + 10.minutes, end_at: tomorrow_7pm + 1.5.hours + 10.minutes)
        end

        before do
          create(:registration, user: user, session: session, status: :confirmed)
        end

        it "is invalid for confirmed registration" do
          registration = build(:registration, user: user, session: other_session, status: :confirmed)
          expect(registration).not_to be_valid
          expect(registration.errors[:base]).to include("Tu es déjà inscrit à une autre session sur le même créneau.")
        end

        it "is valid for waitlisted registration" do
          registration = build(:registration, user: user, session: other_session, status: :waitlisted)
          expect(registration).to be_valid
        end
      end
    end
  end

  describe "weekly training limit" do
    let(:monday) { Time.zone.parse("2025-10-06 10:00:00") }
    let(:next_week_monday) { monday + 7.days }

    around do |example|
      travel_to monday do
        example.run
      end
    end

    context "when multiple trainings in current week" do
      let(:s1) do
        create(:session, session_type: "entrainement", start_at: monday.change(hour: 10),
                        end_at: monday.change(hour: 11), terrain: "Terrain 1", levels: [ level ])
      end
      let(:s2) do
        create(:session, session_type: "entrainement", start_at: monday.change(hour: 18),
                        end_at: monday.change(hour: 19), terrain: "Terrain 2", levels: [ level ])
      end

      before do
        create(:registration, user: user, session: s1, status: :confirmed)
      end

      it "allows multiple registrations" do
        registration = build(:registration, user: user, session: s2, status: :confirmed)
        expect(registration).to be_valid
      end
    end

    context "when second training in non-current week" do
      let(:s1) do
        create(:session, session_type: "entrainement", start_at: next_week_monday.change(hour: 10),
                        end_at: next_week_monday.change(hour: 11), terrain: "Terrain 1", levels: [ level ],
                        registration_opens_at: next_week_monday.change(hour: 0) - 8.days)
      end
      let(:s2) do
        create(:session, session_type: "entrainement", start_at: next_week_monday.change(hour: 18),
                        end_at: next_week_monday.change(hour: 19), terrain: "Terrain 2", levels: [ level ],
                        registration_opens_at: next_week_monday.change(hour: 0) - 8.days)
      end

      before do
        create(:registration, user: user, session: s1, status: :confirmed)
      end

      it "disallows second training" do
        registration = build(:registration, user: user, session: s2, status: :confirmed)
        expect(registration).not_to be_valid
        expect(registration.errors[:base].join).to include("Tu as déjà un entraînement sur cette semaine")
      end
    end

    context "when non-training sessions" do
      let(:s1) do
        create(:session, session_type: "jeu_libre", start_at: next_week_monday.change(hour: 10),
                        end_at: next_week_monday.change(hour: 11), terrain: "Terrain 1")
      end
      let(:s2) do
        create(:session, session_type: "jeu_libre", start_at: next_week_monday.change(hour: 18),
                        end_at: next_week_monday.change(hour: 19), terrain: "Terrain 2")
      end

      before do
        create(:registration, user: user, session: s1, status: :confirmed)
      end

      it "does not apply the limit" do
        registration = build(:registration, user: user, session: s2, status: :confirmed)
        expect(registration).to be_valid
      end
    end
  end

  describe "#required_credits_for" do
    context "when session is coaching_prive" do
      let(:coach) { create(:user) }
      let(:coaching_session) do
        create(:session, user: coach, session_type: "coaching_prive", terrain: "Terrain 1")
      end

      before do
        create(:credit_transaction, user: coach, amount: 2_000)
      end

      it "returns 0" do
        registration = build(:registration, user: user, session: coaching_session)
        expect(registration.required_credits_for(user)).to eq(0)
      end
    end

    context "when session is not coaching_prive" do
      it "returns session price" do
        registration = build(:registration, user: user, session: session)
        expect(registration.required_credits_for(user)).to eq(session.price)
      end
    end
  end
end
