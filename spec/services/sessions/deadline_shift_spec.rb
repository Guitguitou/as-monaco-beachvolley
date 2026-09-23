# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::DeadlineShift do
  let(:old_start) { 5.days.from_now.change(hour: 18) }
  let(:session_record) { create(:session, start_at: old_start, end_at: old_start + 90.minutes) }

  it "moves the untouched deadlines along with the start" do
    deadline = session_record.cancellation_deadline_at
    opens = session_record.registration_opens_at
    session_record.start_at = old_start + 1.day

    described_class.apply(session_record, old_start)

    expect(session_record.cancellation_deadline_at).to eq(deadline + 1.day)
    expect(session_record.registration_opens_at).to eq(opens + 1.day)
  end

  it "keeps a deadline edited by hand" do
    session_record.start_at = old_start + 1.day
    session_record.cancellation_deadline_at = old_start - 2.hours

    described_class.apply(session_record, old_start)

    expect(session_record.cancellation_deadline_at).to eq(old_start - 2.hours)
  end

  it "changes nothing when the start does not move" do
    deadline = session_record.cancellation_deadline_at

    described_class.apply(session_record, old_start)

    expect(session_record.cancellation_deadline_at).to eq(deadline)
  end
end
