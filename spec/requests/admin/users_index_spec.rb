# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin users index", type: :request do
  let(:admin) { create(:user, :admin, last_name: "Admin") }

  before { sign_in admin }

  it "filters, sorts and paginates the users" do
    create(:user, first_name: "Marc", last_name: "Blanc", level: create(:level, gender: "male"))
    26.times { |i| create(:user, last_name: format("Zed%02d", i)) }

    get admin_users_path(gender: "male")

    expect(response).to have_http_status(:success)
    expect(assigns(:users).map(&:last_name)).to eq([ "Blanc" ])

    get admin_users_path(page: 2)

    expect(assigns(:current_page)).to eq(2)
    expect(assigns(:total_pages)).to eq(2)
    expect(assigns(:users).map(&:last_name)).to eq([ "Zed23", "Zed24", "Zed25" ])
  end
end
