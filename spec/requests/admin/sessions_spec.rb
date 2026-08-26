require 'rails_helper'

xdescribe "Admin::Sessions", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/sessions/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/admin/sessions/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/admin/sessions/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/admin/sessions/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/admin/sessions/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/sessions/show"
      expect(response).to have_http_status(:success)
    end
  end
end

describe "Admin::Sessions index", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "affiche la page et limite à 25 sessions par page" do
    30.times { |i| create(:session, user: admin, start_at: (i + 1).days.from_now, end_at: (i + 1).days.from_now + 1.hour) }

    get admin_sessions_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('id="sessions_list"')
    expect(assigns(:sessions).size).to eq(25)
    expect(response.body).to include("Page 1 sur 2")
  end

  it "filtre par type via l'onglet session_type" do
    3.times { |i| create(:session, user: admin, start_at: (i + 1).days.from_now, end_at: (i + 1).days.from_now + 1.hour) }
    create(:session, :tournoi, user: admin, start_at: 10.days.from_now, end_at: 10.days.from_now + 1.hour)

    get admin_sessions_path(session_type: "tournoi")

    expect(response).to have_http_status(:success)
    expect(assigns(:sessions).size).to eq(1)
    expect(assigns(:type_counts)["entrainement"]).to eq(3)
    expect(assigns(:type_counts)["tournoi"]).to eq(1)
  end

  it "sert la page 2" do
    30.times { |i| create(:session, user: admin, start_at: (i + 1).days.from_now, end_at: (i + 1).days.from_now + 1.hour) }

    get admin_sessions_path(page: 2)

    expect(response).to have_http_status(:success)
    expect(assigns(:sessions).size).to eq(5)
    expect(response.body).to include("Page 2 sur 2")
  end
end

# Test for DuplicateSessionService integration
describe DuplicateSessionService, type: :service do
  let(:admin_user) { create(:user, :admin) }
  let(:session) { create(:session, user: admin_user) }

  it "can be called from controller context" do
    result = DuplicateSessionService.new(session, 2).call

    expect(result[:success]).to be true
    expect(result[:created_count]).to eq(2)
    expect(result[:created_sessions].count).to eq(2)
  end
end
