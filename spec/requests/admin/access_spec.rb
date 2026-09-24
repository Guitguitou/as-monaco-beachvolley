# frozen_string_literal: true

require 'rails_helper'

# Règle d'accès commune à l'espace admin (Admin::BaseController) : réservé
# aux admins, sauf les pages financières ouvertes au responsable financier.
RSpec.describe "Admin access", type: :request do
  admin_only_paths = %w[
    /admin/saison
    /admin/users
    /admin/sessions
    /admin/levels
    /admin/terrain_closures
    /admin/stages
    /admin/packs
    /admin/notification_rules
  ]
  staff_paths = %w[
    /admin
    /admin/purchase_history
  ]

  shared_examples "denied" do |path|
    it "redirects #{path} to root with an alert" do
      get path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Accès interdit")
    end
  end

  context "as a player" do
    let(:player) { create(:user) }

    before { sign_in player }

    (admin_only_paths + staff_paths).each { |path| include_examples "denied", path }

    it "cannot promote themselves to admin through the admin users form" do
      patch admin_user_path(player), params: { user: { admin: "1" } }

      expect(response).to redirect_to(root_path)
      expect(player.reload.admin?).to be(false)
    end
  end

  context "as a coach" do
    before { sign_in create(:user, :coach) }

    (admin_only_paths + staff_paths).each { |path| include_examples "denied", path }
  end

  context "as a financial manager" do
    before { sign_in create(:user, :financial_manager) }

    admin_only_paths.each { |path| include_examples "denied", path }

    staff_paths.each do |path|
      it "allows #{path}" do
        get path
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "as an admin" do
    before { sign_in create(:user, :admin) }

    # /admin/notification_rules n'a pas encore de vues : seul le refus est couvert.
    (admin_only_paths + staff_paths - %w[/admin/notification_rules]).each do |path|
      it "allows #{path}" do
        get path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
