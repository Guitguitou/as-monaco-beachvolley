# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tournois", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:tournament) do
    build(:tournament, terrain_names: [ "Terrain 1" ]).tap do |t|
      Tournaments::Save.new(tournament: t, owner: admin).call
    end
  end

  before { sign_in user }

  it "liste les tournois et met le prochain en avant sur l'accueil, avec le lien BVS" do
    tournament

    get tournaments_path
    expect(response.body).to include("Tournoi mixte")

    get home_path
    expect(response.body).to include("Prochain tournoi")
    expect(response.body).to include("https://bvs.example.com/tournoi")
  end

  it "n'affiche le bouton de paiement qu'une fois le paiement ouvert" do
    get tournament_path(tournament)
    expect(response.body).not_to include("Payer 30")

    tournament.pack.update!(active: true)
    get tournament_path(tournament)
    expect(response.body).to include("Payer 30")
  end

  it "affiche « Payé » et refuse un second paiement" do
    tournament.pack.update!(active: true)
    create(:credit_purchase, user: user, pack: tournament.pack, amount_cents: 3000, status: :paid)

    get tournament_path(tournament)
    expect(response.body).to include("Payé")

    post buy_pack_path(tournament.pack)
    expect(response).to redirect_to(tournament_path(tournament))
  end

  it "renvoie une session tournoi vers son tournoi, sans inscription possible" do
    session = tournament.sessions.first

    get session_path(session)
    expect(response).to redirect_to(tournament_path(tournament))
    expect(session.registration_open_state_for(user).first).to be(false)
  end

  describe "admin" do
    before { sign_in admin }

    it "crée un tournoi avec ses images et ses terrains" do
      image = fixture_file_upload(Rails.root.join("app/assets/images/logo.png"), "image/png")

      post admin_tournaments_path, params: { tournament: {
        title: "Tournoi mixte", starts_on: Date.current + 3.weeks, ends_on: Date.current + 3.weeks,
        start_time: "10:00", end_time: "16:00", level: "S3", points: 150, price: 30,
        registration_link: "https://bvs.example.com", terrain_names: [ "", "Terrain 2" ], images: [ image ]
      } }

      created = Tournament.last
      expect(response).to redirect_to(admin_tournament_path(created))
      expect(created.images.count).to eq(1)
      expect(created.sessions.pluck(:terrain)).to eq([ "Terrain 2" ])
      expect(created.pack.active).to be(false)
    end

    it "réordonne les images glissées-déposées" do
      2.times { |i| tournament.images.attach(io: StringIO.new(i.to_s), filename: "#{i}.png", content_type: "image/png") }
      first, second = tournament.ordered_images

      patch reorder_images_admin_tournament_path(tournament), params: { ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:no_content)
      expect(tournament.reload.cover_image).to eq(second)
    end

    it "ouvre le paiement" do
      patch toggle_payment_admin_tournament_path(tournament)
      expect(tournament.pack.reload.active).to be(true)
    end

    it "supprime le tournoi et libère les terrains" do
      tournament
      expect { delete admin_tournament_path(tournament) }.to change(Session, :count).by(-1)
      expect(Tournament.count).to eq(0)
    end

    it "affiche la fiche admin" do
      get admin_tournament_path(tournament)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Ouvrir le paiement")
    end
  end
end
