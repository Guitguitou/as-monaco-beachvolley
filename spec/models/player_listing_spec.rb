# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerListing, type: :model do
  describe "session defaults" do
    context "when a session is provided and fields are blank" do
      it "copies date and times from the session to avoid mismatched slots" do
        session_record = build_stubbed(
          :session,
          start_at: Time.zone.local(2026, 1, 20, 10, 0),
          end_at: Time.zone.local(2026, 1, 20, 12, 0)
        )
        listing = described_class.new(
          user: build_stubbed(:user),
          session: session_record,
          listing_type: "disponible",
          status: "active"
        )

        listing.valid?

        expect(listing.date).to eq(Date.new(2026, 1, 20))
        expect(listing.starts_at.strftime("%H:%M")).to eq("10:00")
        expect(listing.ends_at.strftime("%H:%M")).to eq("12:00")
      end
    end
  end

  describe "time range validation" do
    context "when end time is before start time" do
      it "adds an error to avoid inverted availability windows" do
        listing = described_class.new(
          user: build_stubbed(:user),
          listing_type: "disponible",
          status: "active",
          date: Date.new(2026, 1, 20),
          starts_at: Time.zone.parse("11:00"),
          ends_at: Time.zone.parse("10:00")
        )

        listing.valid?

        expect(listing.errors[:ends_at]).to include("doit être après l'heure de début")
      end
    end
  end
end
