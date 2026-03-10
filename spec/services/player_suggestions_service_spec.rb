# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerSuggestionsService, type: :service do
  describe "#suggested_open_sessions" do
    subject(:suggestions) { described_class.new(user).suggested_open_sessions }

    let(:user) { create(:user, activated_at: Time.current) }
    let!(:level) { create(:level) }

    before do
      user.user_levels.create!(level: level)
    end

    context "when an open session overlaps one active availability" do
      let!(:session) do
        create(
          :session,
          user: create(:user, :coach),
          open_for_matching: true,
          start_at: Time.zone.local(2026, 2, 27, 19, 0),
          end_at: Time.zone.local(2026, 2, 27, 20, 30)
        )
      end

      before do
        session.levels << level
        create(
          :player_listing,
          user: user,
          listing_type: "disponible",
          date: Date.new(2026, 2, 27),
          starts_at: Time.zone.parse("18:30"),
          ends_at: Time.zone.parse("20:00")
        )
      end

      it "returns the session to feed the 'Pour toi' section" do
        expect(suggestions).to include(session)
      end
    end

    context "when the user is already registered to the open session" do
      let!(:session) do
        create(
          :session,
          user: create(:user, :coach),
          open_for_matching: true,
          start_at: Time.zone.local(2026, 2, 27, 19, 0),
          end_at: Time.zone.local(2026, 2, 27, 20, 30)
        )
      end

      before do
        user.balance.update!(amount: 10_000)
        create(:registration, user: user, session: session, status: :confirmed)
      end

      it "excludes the session because there is no useful suggestion anymore" do
        expect(suggestions).not_to include(session)
      end
    end
  end
end
