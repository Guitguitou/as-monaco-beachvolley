# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns success" do
      get root_path, headers: { "HOST" => "localhost" }

      expect(response).to have_http_status(:success)
    end
  end

  describe "sessions per month stat" do
    it "shows the number of sessions in current month" do
      create(:session, start_at: Time.zone.now.beginning_of_month + 5.days, end_at: Time.zone.now.beginning_of_month + 5.days + 90.minutes)
      create(:session, :terrain_2, start_at: Time.zone.now.beginning_of_month + 10.days, end_at: Time.zone.now.beginning_of_month + 10.days + 90.minutes)
      create(:session, :terrain_3, start_at: Time.zone.now.beginning_of_month - 1.day, end_at: Time.zone.now.beginning_of_month - 1.day + 90.minutes)

      get root_path, headers: { "HOST" => "localhost" }

      expect(response.body).to include("Sessions/mois")
      expect(response.body).to include(Session.in_current_month.count.to_s)
    end
  end
end
