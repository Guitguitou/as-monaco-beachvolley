# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin groups", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "liste les joueurs actifs par niveau et signale les multi-groupes" do
    level_a = create(:level, name: "A")
    level_b = create(:level, name: "B")
    multi = create(:user, first_name: "Multi", last_name: "Groupe", level: level_a)
    multi.levels << level_b
    create(:user, first_name: "Désactivé", last_name: "X", level: level_a, disabled_at: Time.current)
    create(:user, first_name: "Inactif", last_name: "Y", level: level_a, activated_at: nil)

    get admin_groups_path

    expect(response).to have_http_status(:success)
    groups = assigns(:level_groups)
    group_a = groups.groups.find { |g| g.level == level_a }
    expect(group_a.members).to eq([ multi ])
    expect(groups.multi_group?(multi)).to be(true)
    expect(response.body).to include("Dans plusieurs groupes")
  end
end
