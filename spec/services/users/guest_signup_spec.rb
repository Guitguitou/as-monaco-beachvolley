# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::GuestSignup do
  def signup(email: "  Nina@Example.com ", first_name: "Nina", last_name: "Neuve")
    described_class.new(email: email, first_name: first_name, last_name: last_name).call
  end

  it "creates the account and sends a link to choose a password" do
    result = nil
    expect { result = signup }.to change { ActionMailer::Base.deliveries.size }.by(1)

    expect(result.user).to have_attributes(email: "nina@example.com", first_name: "Nina", last_name: "Neuve")
    expect(result.error).to be_nil
  end

  it "refuses an email that already has an account" do
    create(:user, email: "nina@example.com")

    expect(signup.error).to eq("Cet email a déjà un compte. Connecte-toi pour acheter ce pack.")
  end

  it "explains an invalid identity" do
    result = signup(email: "pas-un-email")

    expect(result.user).to be_nil
    expect(result.error).to be_present
  end
end
