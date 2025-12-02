# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Payments", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    login_as(admin, scope: :user)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CURRENCY", anything).and_return("EUR")
    allow(ENV).to receive(:fetch).with("APP_HOST", anything).and_return("http://test.host")
    # Mock the instance method call used in the controller
    allow_any_instance_of(Sherlock::CreatePayment).to receive(:call).and_return("<html>payment form</html>")
  end

  describe "GET /admin/payments" do
    it "returns http success" do
      get admin_payments_path
      expect(response).to have_http_status(:success)
    end

    it "shows user credit purchases" do
      create(:credit_purchase, user: admin)
      get admin_payments_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/payments/buy_10_eur" do
    it "creates a credit purchase" do
      expect {
        post buy_10_eur_admin_payments_path
      }.to change { CreditPurchase.count }.by(1)
    end

    it "calls CreatePayment service" do
      expect_any_instance_of(Sherlock::CreatePayment).to receive(:call).and_return("<html>payment form</html>")
      post buy_10_eur_admin_payments_path
    end

    it "renders payment HTML" do
      post buy_10_eur_admin_payments_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("payment form")
    end

    context "when payment creation fails" do
      before do
        allow_any_instance_of(Sherlock::CreatePayment).to receive(:call).and_raise(StandardError.new("Payment error"))
        allow(Rails.logger).to receive(:error)
      end

      it "redirects with error message" do
        post buy_10_eur_admin_payments_path
        expect(response).to redirect_to(admin_payments_path)
        expect(flash[:alert]).to include("Erreur")
      end
    end
  end

  context "when user is not admin" do
    let(:regular_user) { create(:user, activated_at: Time.current) }

    before do
      login_as(regular_user, scope: :user)
    end

    it "redirects with alert" do
      get admin_payments_path
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include("Accès interdit")
    end
  end
end

