# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::AdminFilterQuery do
  let!(:zoe) { create(:user, first_name: "Zoé", last_name: "Arnaud", email: "zoe@example.com", license_type: "competition") }
  let!(:marc) { create(:user, first_name: "Marc", last_name: "Blanc", email: "marc@club.fr", license_type: "loisir", level: create(:level, gender: "male")) }

  def filter(params)
    described_class.call(relation: User.all, params: ActionController::Parameters.new(params)).to_a
  end

  it "searches the name or the email" do
    expect(filter(q: " club ")).to eq([ marc ])
    expect(filter(q: "arnaud")).to eq([ zoe ])
  end

  it "filters by level gender and license" do
    expect(filter(gender: "male")).to eq([ marc ])
    expect(filter(license_type: "competition")).to eq([ zoe ])
  end

  it "sorts by name by default, and by an allowed column otherwise" do
    expect(filter({})).to eq([ zoe, marc ])
    expect(filter(sort: "email", direction: "desc")).to eq([ zoe, marc ])
    expect(filter(sort: "email")).to eq([ marc, zoe ])
    expect(filter(sort: "password", direction: "desc")).to eq([ zoe, marc ])
  end
end
