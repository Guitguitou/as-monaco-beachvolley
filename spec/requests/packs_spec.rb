require 'rails_helper'

RSpec.describe "Packs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/packs/index"
      expect(response).to have_http_status(:success)
    end
  end

end
