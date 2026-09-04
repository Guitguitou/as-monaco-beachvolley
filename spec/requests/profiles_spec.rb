# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, activated_at: 1.year.ago) }

  before { login_as(user, scope: :user) }

  describe "GET /profile" do
    it "renders the season tab by default" do
      get profile_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Ma saison")
      expect(response.body).to include("Réglages")
    end

    it "falls back to the season tab for an unknown tab" do
      get profile_path, params: { tab: "n-importe-quoi" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mes stats")
    end

    it "displays the credit balance" do
      create(:credit_transaction, user: user, amount: 1000, transaction_type: :purchase)

      get profile_path

      expect(response.body).to include("1 000").or include("1000")
    end

    # Le solde était le bloc le plus visible de la page et n'avait aucun lien
    # vers la boutique.
    it "links the balance to the shop" do
      get profile_path

      expect(response.body).to include(packs_path)
    end

    # L'onglet « Mes sessions » dupliquait /me/sessions : les compteurs y
    # renvoient désormais.
    it "links the session counters to /me/sessions" do
      get profile_path

      expect(response.body).to include(me_sessions_path)
    end

    it "renders the settings tab with the identity form" do
      get profile_path, params: { tab: "settings" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mon identité")
      expect(response.body).to include("Enregistrer")
    end

    it "serves the tab bar inside the turbo frame" do
      get profile_path, headers: { "Turbo-Frame" => "profile_tab" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("profile_tab")
    end
  end

  describe "the licence block" do
    context "when the account is not activated" do
      let(:user) { create(:user, activated_at: nil) }

      # /profile est l'une des seules pages ouvertes aux comptes non activés,
      # et n'y disait rien de la licence.
      it "explains the licence and offers to pay it" do
        get profile_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Licence à régler")
        expect(response.body).to include("Régler ma licence")
      end

      it "hides the stats block" do
        get profile_path

        expect(response.body).not_to include("Dernière session")
      end
    end

    context "when the account is activated" do
      let(:user) { create(:user, activated_at: 1.day.ago, license_type: "competition") }

      it "shows the licence type and the priority window" do
        get profile_path

        expect(response.body).to include("Licence active")
        expect(response.body).to include("Compétition")
      end
    end
  end

  describe "the coaching tab" do
    context "as a plain player" do
      it "is not offered" do
        get profile_path

        expect(response.body).not_to include("Mon encadrement")
      end

      # Forcer ?tab=coaching ne doit pas rendre l'onglet.
      it "falls back to the season tab when forced in the URL" do
        get profile_path, params: { tab: "coaching" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Mes stats")
        expect(response.body).not_to include("Les sessions dont tu es le titulaire")
      end
    end

    context "as a coach" do
      let(:user) { create(:user, :coach, activated_at: 1.year.ago, salary_per_training_cents: 5000) }

      it "is offered and shows the earnings" do
        get profile_path, params: { tab: "coaching" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Mes revenus")
        expect(response.body).to include("Les sessions dont tu es le titulaire")
      end

      # Seul point d'entrée de l'app vers /coach/trainings, absent de tous
      # les menus.
      it "links to the training library" do
        get profile_path, params: { tab: "coaching" }

        expect(response.body).to include(coach_trainings_path)
      end
    end

    context "as a responsable" do
      let(:user) { create(:user, :responsable, activated_at: 1.year.ago) }

      it "shows the supervised sessions and the annonces" do
        get profile_path, params: { tab: "coaching" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Les sessions dont tu es le titulaire")
        expect(response.body).to include("Mes annonces")
      end

      # Coach::TrainingsController#ensure_coach_or_admin! le redirigerait.
      it "does not offer the coach-only library" do
        get profile_path, params: { tab: "coaching" }

        expect(response.body).not_to include(coach_trainings_path)
      end

      it "does not show earnings" do
        get profile_path, params: { tab: "coaching" }

        expect(response.body).not_to include("Mes revenus")
      end
    end
  end

  describe "role badges" do
    # Le responsable financier n'était badgé nulle part dans l'app.
    context "as a financial manager" do
      let(:user) { create(:user, :financial_manager, activated_at: 1.year.ago) }

      it "is labelled and gets an admin shortcut" do
        get profile_path, params: { tab: "settings" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Responsable financier")
        expect(response.body).to include(admin_root_path)
      end
    end

    context "as an admin" do
      let(:user) { create(:user, :admin, activated_at: 1.year.ago) }

      it "is labelled and sees the coaching tab" do
        get profile_path

        expect(response.body).to include("Admin")
        expect(response.body).to include("Mon encadrement")
      end
    end
  end

  describe "the money history" do
    it "shows the credits sub-tab by default" do
      get profile_path

      expect(response.body).to include("Mon argent")
      expect(response.body).to include("Crédits")
    end

    # Les achats réels (montant en euros, référence) n'étaient jamais montrés.
    it "shows the purchases sub-tab" do
      pack = create(:pack, name: "Licence saison")
      create(:credit_purchase, user: user, pack: pack, amount_cents: 12_000, status: "paid", paid_at: 1.day.ago)

      get profile_path, params: { history: "purchases" }

      expect(response.body).to include("Licence saison")
      expect(response.body).to include("Payé")
    end

    it "paginates rather than loading everything" do
      25.times { |i| create(:credit_transaction, user: user, amount: i + 1, transaction_type: :purchase) }

      get profile_path

      expect(response.body).to include("Page 1 sur 2")
    end
  end

  # Le point de sécurité central de la refonte.
  describe "PATCH /profile" do
    it "updates the name" do
      patch profile_path, params: { user: { first_name: "Zoé", last_name: "Martin" } }

      expect(response).to redirect_to(profile_path(tab: "settings"))
      expect(user.reload.first_name).to eq("Zoé")
      expect(user.last_name).to eq("Martin")
    end

    it "ignores every privileged attribute" do
      other_level = create(:level)

      patch profile_path, params: { user: {
        first_name: "Zoé",
        last_name: "Martin",
        admin: true,
        coach: true,
        responsable: true,
        financial_manager: true,
        salary_per_training: 999,
        license_type: "competition",
        next_season_renewed: true,
        activated_at: Time.current,
        disabled_at: Time.current,
        level_ids: [ other_level.id ],
        email: "pirate@example.com"
      } }

      user.reload

      expect(user.first_name).to eq("Zoé")
      expect(user).not_to be_admin
      expect(user).not_to be_coach
      expect(user).not_to be_responsable
      expect(user).not_to be_financial_manager
      expect(user.salary_per_training_cents).to eq(0)
      expect(user.license_type).to be_nil
      expect(user).not_to be_next_season_renewed
      expect(user.disabled_at).to be_nil
      expect(user.levels).to be_empty
      expect(user.email).not_to eq("pirate@example.com")
    end

    it "re-renders the settings tab with a 422 when the name is blank" do
      patch profile_path, params: { user: { first_name: "", last_name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Mon identité")
      expect(user.reload.first_name).to eq("John")
    end

    it "cannot touch another user" do
      other = create(:user, first_name: "Intouchable")

      patch profile_path, params: { user: { first_name: "Piraté", last_name: "Martin" } }

      expect(other.reload.first_name).to eq("Intouchable")
    end
  end
end
