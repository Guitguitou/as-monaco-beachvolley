# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::Invitations do
  include ActiveJob::TestHelper

  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user) }
  let(:friend) { create(:user) }
  let(:start_at) { 3.days.from_now.change(hour: 19) }
  let(:session) { create(:session, :jeu_libre, user: coach, start_at: start_at, end_at: start_at + 90.minutes) }
  let(:invitations) { described_class.new(session: session, inviter: player) }

  before { create(:registration, user: player, session: session, status: :confirmed) }

  it "lets a registered player invite members to a free play" do
    expect { invitations.invite([ friend.id ], url: "/sessions/#{session.id}") }
      .to change(SessionInvitation, :count).by(1)
      .and have_enqueued_job(SendPushNotificationJob).with(friend.id, hash_including(url: "/sessions/#{session.id}"))
  end

  it "refuses players who are not part of the session" do
    outsider = described_class.new(session: session, inviter: friend)

    expect(outsider).not_to be_allowed
    expect(outsider.invite([ player.id ], url: "/").sent).to eq(0)
  end

  it "only allows free plays" do
    training = create(:session, :entrainement, user: coach, start_at: start_at + 1.day, end_at: start_at + 1.day + 2.hours)
    create(:registration, user: player, session: training, status: :confirmed)

    expect(described_class.new(session: training, inviter: player)).not_to be_allowed
  end

  it "skips registered, already invited and self" do
    invitations.invite([ friend.id ], url: "/")

    expect(invitations.invitable_users).not_to include(player, friend)
    expect(invitations.invite([ friend.id, player.id ], url: "/").sent).to eq(0)
  end

it "n'invite pas un joueur dont le dossier est incomplet" do
    sans_dossier = create(:user, dossier_complet: false)

    expect(invitations.invitable_users).to include(friend)
    expect(invitations.invitable_users).not_to include(sans_dossier)
  end

  it "caps the invitations per player" do
    stub_const("#{described_class}::MAX_PER_INVITER", 1)
    others = create_list(:user, 2)

    expect(invitations.invite(others.map(&:id), url: "/").sent).to eq(1)
    expect(invitations.remaining).to eq(0)
  end
end
