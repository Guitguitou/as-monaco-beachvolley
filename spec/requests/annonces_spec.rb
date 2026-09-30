# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Annonces", type: :request do
  let(:activated) { create(:user, activated_at: Time.current) }
  let(:start_at) { (Time.current + 2.days).change(hour: 19, min: 0) }

  describe "POST /annonces" do
    let(:valid_params) do
      {
        annonce: {
          title: "Jeu libre du soir",
          min_players: 4,
          slots_attributes: {
            "0" => { start_at: start_at, end_at: start_at + 2.hours }
          }
        }
      }
    end

    context "activated user" do
      before { login_as(activated, scope: :user) }

      it "creates an annonce owned by the current user" do
        expect { post annonces_path, params: valid_params }.to change(Annonce, :count).by(1)
        expect(Annonce.last.user).to eq(activated)
        expect(response).to redirect_to(Annonce.last)
      end

      it "notifie les joueurs éligibles à la création" do
        eligible = create(:user, activated_at: Time.current)
        notifier = instance_double(Annonces::Notifier, notify_eligible_players: true)
        allow(Annonces::Notifier).to receive(:new).and_return(notifier)

        post annonces_path, params: valid_params

        expect(notifier).to have_received(:notify_eligible_players)
      end
    end

    context "non-activated user" do
      before { login_as(create(:user, activated_at: nil), scope: :user) }

      it "is forbidden" do
        expect { post annonces_path, params: valid_params }.not_to change(Annonce, :count)
      end
    end
  end

  describe "POST /annonces/:id/toggle_availability" do
    let(:annonce) { create(:annonce, :with_slot, user: create(:user)) }
    let(:slot) { annonce.slots.first }

    before { login_as(activated, scope: :user) }

    it "adds then removes the current user's availability" do
      expect {
        post toggle_availability_annonce_path(annonce, slot_id: slot.id)
      }.to change { AnnonceAvailability.where(annonce_slot: slot, user: activated).count }.from(0).to(1)

      expect {
        post toggle_availability_annonce_path(annonce, slot_id: slot.id)
      }.to change { AnnonceAvailability.where(annonce_slot: slot, user: activated).count }.from(1).to(0)
    end
  end

  describe "GET/PATCH /annonces/:id/confirm" do
    let(:creator) { create(:user, activated_at: Time.current) }
    let(:annonce) { create(:annonce, user: creator, min_players: 2, slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ]) }
    let(:slot) { annonce.slots.first }

    before do
      2.times do
        u = create(:user)
        create(:credit_transaction, user: u, amount: 10_000)
        create(:annonce_availability, annonce_slot: slot, user: u)
      end
    end

    it "confirme et crée une session (créateur uniquement)" do
      login_as(creator, scope: :user)
      expect {
        patch confirm_annonce_path(annonce), params: { slot_id: slot.id, terrain: "Terrain 1" }
      }.to change(Session, :count).by(1)
      expect(annonce.reload).to be_confirmed
      expect(response).to redirect_to(annonce.reload.session)
    end

    it "interdit la confirmation par un autre utilisateur" do
      login_as(activated, scope: :user)
      expect {
        patch confirm_annonce_path(annonce), params: { slot_id: slot.id, terrain: "Terrain 1" }
      }.to raise_error(CanCan::AccessDenied)
      expect(Session.count).to eq(0)
    end
  end
end

RSpec.describe "Jeu libre", type: :request do
  let(:player) { create(:user) }

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    login_as(player, scope: :user)
  end

  it "sert la page sous /jeu-libre" do
    expect(annonces_path).to eq("/jeu-libre")

    get annonces_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tu es libre quand ?")
  end

  it "redirige les anciens liens /annonces reçus en push" do
    annonce = create(:annonce, :with_slot)

    get "/annonces/#{annonce.id}"

    expect(response).to redirect_to("/jeu-libre/#{annonce.id}")
  end

  describe "POST /jeu-libre/quick" do
    it "lance une partie sur le créneau choisi" do
      expect { post quick_annonces_path(slot: "demain_soir") }.to change(Annonce, :count).by(1)

      expect(response).to redirect_to(Annonce.last)
      expect(Annonce.last.slots.first.available_users).to eq([ player ])
    end

    it "refuse un créneau inconnu" do
      expect { post quick_annonces_path(slot: "hier") }.not_to change(Annonce, :count)

      expect(flash[:alert]).to eq("Ce créneau n'est plus disponible.")
    end
  end

  it "met en avant les parties à rejoindre sur Mon terrain" do
    create(:annonce, :with_slot, user: create(:user, first_name: "Julie"))

    get home_path

    expect(response.body).to include("Ça joue bientôt", "Il manque 4 joueurs", "J&#39;en suis")
  end

  it "revient sur la page d'origine après « J'en suis »" do
    annonce = create(:annonce, :with_slot)

    post toggle_availability_annonce_path(annonce, slot_id: annonce.slots.first.id), headers: { "HTTP_REFERER" => home_url }

    expect(response).to redirect_to(home_url)
  end
end
