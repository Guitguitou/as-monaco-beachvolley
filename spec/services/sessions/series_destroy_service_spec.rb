require "rails_helper"

RSpec.describe Sessions::SeriesDestroyService do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }

  # Une série de 3 sessions (source + 2 suivantes) via la duplication réelle.
  let(:source) do
    create(:session, user: coach, title: "Série",
                     start_at: 2.days.from_now.change(hour: 18),
                     end_at: 2.days.from_now.change(hour: 20))
  end

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  def build_series
    DuplicateSessionService.new(source, 2).call
    source.reload
  end

  describe "scope this" do
    it "destroys only the given session" do
      build_series
      expect {
        described_class.call(session: source, scope: "this")
      }.to change(Session, :count).by(-1)
      expect(Session.where(series_id: source.series_id).count).to eq(2)
    end
  end

  describe "scope following" do
    it "destroys the session and its followers, keeping earlier ones" do
      build_series
      # Une session antérieure de la même série ne doit pas être touchée.
      earlier = create(:session, user: coach, series_id: source.series_id,
                                 start_at: source.start_at - 1.week,
                                 end_at: source.end_at - 1.week)

      expect {
        described_class.call(session: source, scope: "following")
      }.to change(Session, :count).by(-3)

      expect(Session.exists?(earlier.id)).to be true
    end

    it "refunds confirmed participants of destroyed sessions" do
      build_series
      player = create(:user, activated_at: Time.current)
      create(:credit_transaction, user: player, amount: 1000)
      create(:registration, user: player, session: source, status: :confirmed)

      expect {
        described_class.call(session: source, scope: "following")
      }.to change { player.reload.credit_balance }.by(source.price)
    end
  end
end
