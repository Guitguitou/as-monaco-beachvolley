require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/registrations/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/registrations/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
