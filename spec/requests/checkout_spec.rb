# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Checkout", type: :request do
  describe "GET /checkout/success" do
    context "when user is signed in" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "redirects to admin payments path" do
        get checkout_success_path
        expect(response).to redirect_to(admin_payments_path)
      end

      it "sets a success flash message" do
        get checkout_success_path
        expect(flash[:notice]).to include("Paiement confirmé")
      end

      it "handles POST request" do
        post checkout_success_path
        expect(response).to redirect_to(admin_payments_path)
      end
    end

    context "when user is not signed in" do
      it "redirects to packs path" do
        get checkout_success_path
        expect(response).to redirect_to(packs_path)
      end

      it "sets a success flash message" do
        get checkout_success_path
        expect(flash[:notice]).to include("Paiement confirmé")
      end
    end
  end

  describe "GET /checkout/cancel" do
    context "when user is signed in" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "redirects to admin payments path" do
        get checkout_cancel_path
        expect(response).to redirect_to(admin_payments_path)
      end

      it "sets an alert flash message" do
        get checkout_cancel_path
        expect(flash[:alert]).to include("Paiement annulé")
      end
    end

    context "when user is not signed in" do
      it "redirects to packs path" do
        get checkout_cancel_path
        expect(response).to redirect_to(packs_path)
      end

      it "sets an alert flash message" do
        get checkout_cancel_path
        expect(flash[:alert]).to include("Paiement annulé")
      end
    end
  end
end

