# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::AdminUpdate do
  let(:admin) { create(:user, :admin) }
  let(:start_at) { 3.days.from_now.change(hour: 18) }
  let(:session_record) { create(:session, user: admin, title: "Origine", start_at: start_at, end_at: start_at + 2.hours) }

  def update(attributes, scope: "this", level_priorities: nil, levels_submitted: false, &block)
    described_class.new(session: session_record, attributes: attributes, level_priorities: level_priorities,
                        levels_submitted: levels_submitted, scope: scope).call(&block || proc { })
  end

  it "saves, shifts the untouched deadlines and runs the given follow-up" do
    deadline = session_record.cancellation_deadline_at
    followed_up = false

    result = update({ start_at: start_at + 1.hour, end_at: start_at + 3.hours }) { followed_up = true }

    expect(result).to have_attributes(saved?: true, notice: "Session mise à jour avec succès.", failures: [])
    expect(session_record.reload.cancellation_deadline_at).to eq(deadline + 1.hour)
    expect(followed_up).to be(true)
  end

  it "reports an invalid edit without following up" do
    followed_up = false

    result = update({ end_at: start_at - 1.hour }) { followed_up = true }

    expect(result.saved?).to be(false)
    expect(followed_up).to be(false)
  end

  it "rebalances a training when its places change" do
    allow(session_record).to receive(:rebalance!)

    update({ max_players: 8 })

    expect(session_record).to have_received(:rebalance!)
  end

  it "does not rebalance when neither places nor groups change" do
    allow(session_record).to receive(:rebalance!)

    update({ title: "Nouveau titre" })

    expect(session_record).not_to have_received(:rebalance!)
  end

  it "carries the edit to the following sessions of the series" do
    DuplicateSessionService.new(session_record, 2).call
    session_record.reload

    result = update({ title: "Titre série" }, scope: "following")

    expect(result.notice).to eq("Session et 2 suivante(s) mises à jour ✅")
    expect(session_record.series_sessions.pluck(:title)).to all(eq("Titre série"))
  end
end
