require 'rails_helper'

RSpec.describe "Annonces views smoke", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }
  before { login_as(user, scope: :user) }

  it "renders index" do
    get annonces_path
    expect(response).to have_http_status(:ok)
  end

  it "renders new" do
    get new_annonce_path
    expect(response).to have_http_status(:ok)
  end

  it "renders show with a slot and toggle button" do
    start_at = (Time.current + 2.days).change(hour: 19, min: 0)
    annonce = create(:annonce, user: create(:user),
                     slots: [build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours)])
    get annonce_path(annonce)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Je suis dispo")
  end

  it "renders confirm page for the owner" do
    start_at = (Time.current + 2.days).change(hour: 19, min: 0)
    annonce = create(:annonce, user: user, min_players: 1,
                     slots: [build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours)])
    create(:annonce_availability, annonce_slot: annonce.slots.first, user: create(:user))
    get confirm_annonce_path(annonce)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Terrain")
  end

  it "renders show with WhatsApp button when confirmed" do
    start_at = (Time.current + 2.days).change(hour: 19, min: 0)
    session = create(:session, :jeu_libre, start_at: start_at, end_at: start_at + 2.hours)
    annonce = create(:annonce, :confirmed, user: user, session: session,
                     slots: [build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours)])
    get annonce_path(annonce)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("wa.me")
  end
end
