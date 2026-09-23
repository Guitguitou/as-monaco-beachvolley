# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::AdminAttributes do
  let(:params) { ActionController::Parameters.new(first_name: "Léa", password: "", password_confirmation: "").permit! }

  it "gives a new member a random password when the admin leaves it blank" do
    user = described_class.apply(User.new(email: "lea@example.com"), params, activate: nil)

    expect(user.first_name).to eq("Léa")
    expect(user.password).to be_present
    expect(user.activated_at).to be_nil
  end

  it "keeps the current password of a member when the field is left blank" do
    user = create(:user, password: "secret123", password_confirmation: "secret123")

    described_class.apply(user, params, activate: nil).save!

    expect(user.reload.valid_password?("secret123")).to be(true)
  end

  it "activates or deactivates the member from the checkbox" do
    user = create(:user, activated_at: nil)

    expect(described_class.apply(user, params, activate: "1").activated_at).to be_present
    expect(described_class.apply(user, params, activate: "0").activated_at).to be_nil
  end

  it "keeps the first activation date" do
    activated_at = 2.days.ago.change(usec: 0)
    user = create(:user, activated_at: activated_at)

    expect(described_class.apply(user, params, activate: "1").activated_at).to eq(activated_at)
  end
end
