# frozen_string_literal: true

require "rails_helper"

# Couvre le happy-path de l'édition admin : recalcul des deadlines quand la date
# change, et propagation « cette session et les suivantes » sur une série.
RSpec.describe "Admin sessions reschedule", type: :request do
  let(:admin) { create(:user, :admin, activated_at: Time.current) }

  let(:source) do
    create(:session, user: admin, title: "Origine",
                     start_at: 3.days.from_now.change(hour: 18, min: 0),
                     end_at: 3.days.from_now.change(hour: 20, min: 0))
  end

  before { sign_in admin }

  def base_params(session)
    {
      title: session.title, session_type: session.session_type, terrain: session.terrain,
      user_id: session.user_id, max_players: session.max_players
    }
  end

  describe "PATCH update on a single session" do
    it "shifts deadlines by the same delta when start_at changes and deadlines untouched" do
      old_deadline = source.cancellation_deadline_at
      old_opens = source.registration_opens_at
      new_start = source.start_at + 2.hours

      patch admin_session_path(source), params: {
        session: base_params(source).merge(
          start_at: new_start.strftime("%Y-%m-%dT%H:%M"),
          end_at: (source.end_at + 2.hours).strftime("%Y-%m-%dT%H:%M"),
          cancellation_deadline_at: old_deadline.strftime("%Y-%m-%dT%H:%M"),
          registration_opens_at: old_opens.strftime("%Y-%m-%dT%H:%M")
        )
      }

      source.reload
      expect(source.cancellation_deadline_at).to be_within(1.minute).of(old_deadline + 2.hours)
      expect(source.registration_opens_at).to be_within(1.minute).of(old_opens + 2.hours)
    end
  end

  describe "PATCH update with scope=following" do
    it "propagates the change to following sessions of the series" do
      DuplicateSessionService.new(source, 2).call
      source.reload
      follower = source.series_sessions.where("start_at > ?", source.start_at).order(:start_at).first
      follower_start_before = follower.start_at

      patch admin_session_path(source), params: {
        scope: "following",
        session: base_params(source).merge(
          title: "Titre série",
          start_at: (source.start_at + 1.hour).strftime("%Y-%m-%dT%H:%M"),
          end_at: (source.end_at + 1.hour).strftime("%Y-%m-%dT%H:%M")
        )
      }

      expect(response).to redirect_to(admin_session_path(source))
      follower.reload
      expect(follower.title).to eq("Titre série")
      expect(follower.start_at).to be_within(1.minute).of(follower_start_before + 1.hour)
    end
  end
end
