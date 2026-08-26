require "rails_helper"

RSpec.describe Sessions::SeriesUpdateService do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:source) do
    create(:session, user: coach, title: "Origine",
                     start_at: 2.days.from_now.change(hour: 18, min: 0),
                     end_at: 2.days.from_now.change(hour: 20, min: 0),
                     cancellation_deadline_at: 2.days.from_now.change(hour: 22, min: 0) - 1.day,
                     registration_opens_at: 2.days.from_now.change(hour: 18, min: 0) - 7.days)
  end

  # Série réelle : source + 2 suivantes.
  before do
    DuplicateSessionService.new(source, 2).call
    source.reload
  end

  def followers
    source.series_sessions.where("start_at > ?", source.start_at).order(:start_at).to_a
  end

  it "shifts following sessions dates and deadlines by the same delta" do
    old_start = source.start_at
    followers_before = followers.map { |s| [ s.id, s.start_at, s.cancellation_deadline_at, s.registration_opens_at ] }

    source.update!(start_at: old_start + 1.hour, end_at: source.end_at + 1.hour)
    result = described_class.call(edited_session: source, old_start: old_start, scope: "following")

    expect(result[:updated_count]).to eq(2)
    expect(result[:failures]).to be_empty

    followers_before.each do |id, start_before, deadline_before, opens_before|
      s = Session.find(id)
      expect(s.start_at).to be_within(1.second).of(start_before + 1.hour)
      expect(s.cancellation_deadline_at).to be_within(1.second).of(deadline_before + 1.hour)
      expect(s.registration_opens_at).to be_within(1.second).of(opens_before + 1.hour)
    end
  end

  it "propagates content to following sessions" do
    old_start = source.start_at
    source.update!(title: "Nouveau titre", max_players: 8)

    described_class.call(edited_session: source, old_start: old_start, scope: "following")

    followers.each do |s|
      expect(s.title).to eq("Nouveau titre")
      expect(s.max_players).to eq(8)
    end
  end

  it "does not touch earlier sessions of the series" do
    earlier = create(:session, user: coach, series_id: source.series_id,
                               start_at: source.start_at - 1.week,
                               end_at: source.end_at - 1.week)
    old_start = source.start_at
    source.update!(start_at: old_start + 1.hour, end_at: source.end_at + 1.hour)

    described_class.call(edited_session: source, old_start: old_start, scope: "following")

    expect(earlier.reload.start_at).to be_within(1.second).of(source.start_at - 1.week - 1.hour)
  end

  it "lists failures without blocking valid updates" do
    old_start = source.start_at
    first_follower = followers.first

    # Décalage de +3h : le nouveau créneau du 1er suivant (21h-23h) ne chevauche
    # pas son créneau actuel (18h-20h), mais un bloqueur l'y attend => save en échec.
    create(:session, user: coach, terrain: source.terrain,
                     start_at: first_follower.start_at + 3.hours,
                     end_at: first_follower.end_at + 3.hours)

    source.update!(start_at: old_start + 3.hours, end_at: source.end_at + 3.hours)
    result = described_class.call(edited_session: source, old_start: old_start, scope: "following")

    expect(result[:updated_count]).to eq(1)
    expect(result[:failures].size).to eq(1)
  end

  it "does nothing when scope is not following" do
    old_start = source.start_at
    source.update!(start_at: old_start + 1.hour, end_at: source.end_at + 1.hour)

    result = described_class.call(edited_session: source, old_start: old_start, scope: "this")
    expect(result[:updated_count]).to eq(0)
  end
end
