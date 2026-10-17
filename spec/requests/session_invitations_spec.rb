# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session invitations", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user, first_name: "Léa", last_name: "Martin") }
  let(:friend) { create(:user, first_name: "Tom", last_name: "Blanc") }
  let(:start_at) { 2.days.from_now.change(hour: 19) }
  let(:session_record) { create(:session, :jeu_libre, user: coach, start_at: start_at, end_at: start_at + 90.minutes) }

  before { create(:registration, user: player, session: session_record, status: :confirmed) }

  it "lets a registered player invite a member" do
    login_as player, scope: :user

    expect { post session_invitations_path(session_record), params: { invitee_ids: [ friend.id ] } }
      .to change(SessionInvitation, :count).by(1)
    expect(response).to redirect_to(session_path(session_record))
    expect(flash[:notice]).to eq("Invitation envoyée à Tom.")
  end

  it "shows the invite form to registered players only" do
    login_as player, scope: :user
    get session_path(session_record)
    expect(response.body).to include("Inviter des joueurs")

    login_as friend, scope: :user
    get session_path(session_record)
    expect(response.body).not_to include("Inviter des joueurs")
  end

  it "tells the invitee who invited them" do
    SessionInvitation.create!(session: session_record, inviter: player, invitee: friend)
    login_as friend, scope: :user

    get session_path(session_record)

    expect(response.body).to include("Léa Martin</span> t'invite à jouer")
  end
end
