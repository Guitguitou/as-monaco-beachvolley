# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpireAnnoncesJob do
  it "expire les parties ouvertes dont tous les créneaux sont passés" do
    past = create(:annonce, :with_slot)
    past.slots.first.update_columns(start_at: 1.day.ago, end_at: 1.day.ago + 2.hours)
    upcoming = create(:annonce, :with_slot)
    confirmed = create(:annonce, :with_slot, :confirmed)
    confirmed.slots.first.update_columns(start_at: 1.day.ago, end_at: 1.day.ago + 2.hours)

    described_class.perform_now

    expect(past.reload).to be_expired
    expect(upcoming.reload).to be_open
    expect(confirmed.reload).to be_confirmed
  end
end
