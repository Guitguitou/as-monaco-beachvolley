# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/support/shared_examples/captive_footer")

RSpec.describe SessionMailer, type: :mailer do
  let(:user) { create(:user, first_name: "Bob", email: "bob@example.com") }

  describe "#promoted_to_main_list" do
    let(:session_record) do
      create(:session,
        title: "Jeu libre du soir",
        start_at: Time.zone.local(2026, 6, 15, 19, 30),
        end_at: Time.zone.local(2026, 6, 15, 21, 0))
    end

    subject(:mail) { described_class.promoted_to_main_list(user, session_record) }

    it "notifies the user they moved from waitlist to main list" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Tu passes en liste principale – Jeu libre du soir du 15/06/2026")

      html_body = mail.html_part.body.to_s
      expect(html_body).to include("Bonjour Bob")
      expect(html_body).to include("tu viens de passer en liste principale")
      expect(html_body).to include("Jeu libre du soir")
      expect(html_body).to include("15/06/2026")
      expect(html_body).to include("19h30")
    end

    it_behaves_like "includes the Captive footer"
  end

  describe "#session_cancelled" do
    subject(:mail) do
      described_class.session_cancelled(
        user,
        session_name: "Tournoi été",
        session_date: "20/07/2026"
      )
    end

    it "tells the user the session is cancelled and credits are refunded" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Session annulée – Tournoi été du 20/07/2026")

      html_body = mail.html_part.body.to_s
      expect(html_body).to include("Bonjour Bob")
      expect(html_body).to include("Tournoi été")
      expect(html_body).to include("20/07/2026")
      expect(html_body).to include("a été annulée")
      expect(html_body).to include("recrédités")
    end

    it_behaves_like "includes the Captive footer"
  end
end
