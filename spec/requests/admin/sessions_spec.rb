require "rails_helper"

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:coach) { create(:user, :coach) }
  let!(:session_record) do
    create(
      :session,
      user: coach,
      title: "Session Admin",
      terrain: "Terrain 1",
      start_at: 8.days.from_now.change(hour: 18),
      end_at: 8.days.from_now.change(hour: 19, min: 30)
    )
  end

  before do
    host! "localhost"
    allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
    login_as admin, scope: :user
  end

  describe "GET /admin/sessions" do
    it "returns success and displays sessions" do
      get admin_sessions_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Session Admin")
    end
  end

  describe "POST /admin/sessions" do
    let(:valid_params) do
      {
        session: {
          title: "Nouvelle session",
          description: "Test",
          start_at: 2.days.from_now.change(hour: 18),
          end_at: 2.days.from_now.change(hour: 19, min: 30),
          session_type: "entrainement",
          max_players: 12,
          terrain: "Terrain 1",
          user_id: coach.id,
          price: 300
        }
      }
    end

    it "creates a session and redirects to show" do
      expect do
        post admin_sessions_path, params: valid_params
      end.to change(Session, :count).by(1)

      created = Session.order(:created_at).last
      expect(response).to redirect_to(admin_session_path(created))
      expect(created.title).to eq("Nouvelle session")
    end
  end

  describe "PATCH /admin/sessions/:id" do
    it "updates a session and redirects to show" do
      patch admin_session_path(session_record), params: { session: { title: "Session modifiée" } }

      expect(response).to redirect_to(admin_session_path(session_record))
      expect(session_record.reload.title).to eq("Session modifiée")
    end
  end

  describe "DELETE /admin/sessions/:id" do
    it "deletes session and redirects to index" do
      expect do
        delete admin_session_path(session_record)
      end.to change(Session, :count).by(-1)

      expect(response).to redirect_to(admin_sessions_path)
    end
  end
end
