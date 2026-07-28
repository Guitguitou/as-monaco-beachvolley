# frozen_string_literal: true

module Ics
  # Value object describing a single calendar event, framework-agnostic.
  # Times must be Time/DateTime objects; they are serialized in UTC by Ics::Calendar.
  Event = Data.define(:uid, :title, :starts_at, :ends_at, :description, :location, :url) do
    def initialize(uid:, title:, starts_at:, ends_at:, description: nil, location: nil, url: nil)
      super
    end
  end
end
