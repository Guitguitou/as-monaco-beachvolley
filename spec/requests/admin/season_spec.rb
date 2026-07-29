# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Season", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user, activated_at: 1.year.ago) }

  describe "GET /admin/saison" do
    context "when user is admin" do
      before { login_as(admin, scope: :user) }

      it "returns http success" do
        get admin_season_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a regular player" do
      before { login_as(player, scope: :user) }

      it "redirects to root" do
        get admin_season_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/saison/reinitialiser" do
    context "when user is admin" do
      before { login_as(admin, scope: :user) }

      it "resets licences and redirects with a notice" do
        kept = create(:user, activated_at: 1.year.ago, next_season_renewed: true)
        dropped = create(:user, activated_at: 1.year.ago, next_season_renewed: false)

        post admin_reset_season_path

        expect(response).to redirect_to(admin_season_path)
        expect(kept.reload.activated?).to be(true)
        expect(kept.next_season_renewed?).to be(false)
        expect(dropped.reload.activated?).to be(false)
      end
    end

    context "when user is a regular player" do
      before { login_as(player, scope: :user) }

      it "does not reset and redirects to root" do
        other = create(:user, activated_at: 1.year.ago, next_season_renewed: false)

        post admin_reset_season_path

        expect(response).to redirect_to(root_path)
        expect(other.reload.activated?).to be(true)
      end
    end
  end
end
