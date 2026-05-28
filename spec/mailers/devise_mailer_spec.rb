# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/support/shared_examples/captive_footer")

# Verrouille le fait que Devise::Mailer hérite d'ApplicationMailer (via
# config.parent_mailer dans config/initializers/devise.rb) et bénéficie donc
# du layout commun et du footer Captive.
RSpec.describe Devise::Mailer, type: :mailer do
  # Force le chargement des routes pour que `Devise.mappings` soit peuplé
  # avant l'appel direct au mailer. Sans ça, l'ordre random de RSpec rend
  # ce test flaky si aucune spec préalable n'a déclenché un URL helper.
  before(:all) { Rails.application.routes_reloader.execute_unless_loaded }

  let(:user) { create(:user, email: "charlie@example.com") }

  it "inherits from ApplicationMailer so the shared layout applies" do
    expect(described_class.ancestors).to include(ApplicationMailer)
  end

  describe "#reset_password_instructions" do
    subject(:mail) { described_class.reset_password_instructions(user, "fake-token") }

    it "delivers a reset password email to the user" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.html_part.body.to_s).to include("Réinitialiser mon mot de passe")
    end

    it_behaves_like "includes the Captive footer"
  end
end
