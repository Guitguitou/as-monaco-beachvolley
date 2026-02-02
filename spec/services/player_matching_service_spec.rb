# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerMatchingService, type: :service do
  describe "#match_between?" do
    subject(:service) { described_class.new(build_stubbed(:user)) }

    ListingStub = Struct.new(:listing_type, :effective_start_at, :effective_end_at, :gender, :effective_level_ids, keyword_init: true)

    context "when types differ and filters are compatible" do
      it "returns true to surface a valid match" do
        listing = ListingStub.new(
          listing_type: "disponible",
          effective_start_at: Time.zone.local(2026, 1, 20, 10, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 12, 0),
          gender: "male",
          effective_level_ids: [1, 2]
        )
        candidate = ListingStub.new(
          listing_type: "recherche",
          effective_start_at: Time.zone.local(2026, 1, 20, 11, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 13, 0),
          gender: "male",
          effective_level_ids: [2, 3]
        )

        expect(service.match_between?(listing, candidate)).to be(true)
      end
    end

    context "when time ranges do not overlap" do
      it "returns false to avoid suggesting unavailable players" do
        listing = ListingStub.new(
          listing_type: "disponible",
          effective_start_at: Time.zone.local(2026, 1, 20, 10, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 11, 0),
          gender: nil,
          effective_level_ids: []
        )
        candidate = ListingStub.new(
          listing_type: "recherche",
          effective_start_at: Time.zone.local(2026, 1, 20, 12, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 13, 0),
          gender: nil,
          effective_level_ids: []
        )

        expect(service.match_between?(listing, candidate)).to be(false)
      end
    end

    context "when genders are incompatible" do
      it "returns false to keep filtering by gender" do
        listing = ListingStub.new(
          listing_type: "disponible",
          effective_start_at: Time.zone.local(2026, 1, 20, 10, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 12, 0),
          gender: "male",
          effective_level_ids: [1]
        )
        candidate = ListingStub.new(
          listing_type: "recherche",
          effective_start_at: Time.zone.local(2026, 1, 20, 11, 0),
          effective_end_at: Time.zone.local(2026, 1, 20, 12, 0),
          gender: "female",
          effective_level_ids: [1]
        )

        expect(service.match_between?(listing, candidate)).to be(false)
      end
    end
  end
end
