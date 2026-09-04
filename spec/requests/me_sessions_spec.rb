# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Me::Sessions", type: :request do
  let(:user) { create(:user, activated_at: 1.year.ago) }

  before { login_as(user, scope: :user) }

  def register(session, status: :confirmed)
    Registration.new(user: user, session: session, status: status).tap { |r| r.save!(validate: false) }
  end

  # La suite tourne actuellement sur la base de développement (.env impose
  # DATABASE_URL) : on choisit des créneaux hors de portée de ces données.
  def session_at(offset, terrain: "Terrain 1")
    @slot = (@slot || 0) + 1
    start_at = (8.years.from_now + offset.days).change(hour: 6 + (@slot * 2) % 16)
    create(:session, terrain: terrain, start_at: start_at, end_at: start_at + 2.hours)
  end

  def past_session_at(offset)
    @slot = (@slot || 0) + 1
    start_at = (8.years.ago + offset.days).change(hour: 6 + (@slot * 2) % 16)
    create(:session, terrain: "Terrain 1", start_at: start_at, end_at: start_at + 2.hours)
  end

  describe "GET /me/sessions" do
    it "shows the upcoming tab by default" do
      register(session_at(3))

      get me_sessions_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("À venir")
      expect(response.body).to include("Passées")
    end

    # sessions_registered passe par confirmed_registrations : une inscription en
    # liste d'attente était totalement invisible pour le joueur.
    it "shows a session the player is waitlisted on" do
      waitlisted = session_at(4)
      waitlisted.update!(title: "Entraînement complet")
      register(waitlisted, status: :waitlisted)

      get me_sessions_path

      expect(response.body).to include("Entraînement complet")
      expect(response.body).to include("liste d&#39;attente")
    end

    it "counts waitlisted sessions in the upcoming tab" do
      register(session_at(2), status: :waitlisted)
      register(session_at(3), status: :confirmed)

      get me_sessions_path

      expect(response.body).to include("liste d&#39;attente")
    end

    it "does not announce a waitlist when there is none" do
      register(session_at(2))

      get me_sessions_path

      expect(response.body).not_to include("liste d&#39;attente")
    end

    it "shows past sessions on the past tab" do
      past = past_session_at(1)
      past.update!(title: "Vieux match")
      register(past)

      get me_sessions_path(filter: "past")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Vieux match")
    end

    it "keeps past sessions off the upcoming tab" do
      past = past_session_at(1)
      past.update!(title: "Vieux match")
      register(past)

      get me_sessions_path

      expect(response.body).not_to include("Vieux match")
    end

    it "renders an empty state with nothing registered" do
      get me_sessions_path

      expect(response.body).to include("Rien de prévu")
    end

    it "falls back to the upcoming tab for an unknown filter" do
      get me_sessions_path(filter: "n-importe-quoi")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Rien de prévu")
    end
  end

  describe "GET /me/sessions/:id" do
    it "opens a confirmed session" do
      session = session_at(3)
      register(session)

      get me_session_path(session)

      expect(response).to have_http_status(:success)
    end

    # Une session où le joueur attend une place doit rester consultable.
    it "opens a waitlisted session" do
      session = session_at(3)
      register(session, status: :waitlisted)

      get me_session_path(session)

      expect(response).to have_http_status(:success)
    end

    it "refuses a session the player is not registered on" do
      session = session_at(3)

      get me_session_path(session)

      expect(response).to have_http_status(:not_found)
    end
  end
end
