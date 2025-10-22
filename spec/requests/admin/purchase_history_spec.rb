require 'rails_helper'

RSpec.describe "Admin::PurchaseHistories", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/purchase_history/index"
      expect(response).to have_http_status(:success)
    end
  end

end
