require "rails_helper"

RSpec.describe SessionMailer, type: :mailer do
  let(:user) { create(:user, first_name: "Emma", email: "emma@example.com") }
  let(:session_record) { create(:session, title: "Entraînement soir") }

  describe "#promoted_to_main_list" do
    it "builds an email with recipient, subject and session context" do
      mail = described_class.promoted_to_main_list(user, session_record)

      expect(mail.to).to eq(["emma@example.com"])
      expect(mail.subject).to include("Tu passes en liste principale")
      expect(mail.subject).to include("Entraînement soir")
      expect(mail.body.encoded).to include("Bonne nouvelle")
    end
  end

  describe "#session_cancelled" do
    it "builds a cancellation email with navigation link context" do
      mail = described_class.session_cancelled(user, session_name: "Jeu Libre", session_date: "10/04/2026")

      expect(mail.to).to eq(["emma@example.com"])
      expect(mail.subject).to eq("Session annulée – Jeu Libre du 10/04/2026")
      expect(mail.text_part.decoded).to include("a été annulée")
      expect(mail.text_part.decoded).to include("Voir les autres sessions")
    end
  end
end
