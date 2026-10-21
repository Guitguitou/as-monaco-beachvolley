require "rails_helper"

RSpec.describe "Séances annulées masquées", type: :request do
  let(:user) { create(:user, activated_at: Time.current, dossier_complet: true) }
  let(:start_at) { 2.days.from_now.change(hour: 18) }

  before do
    login_as user, scope: :user
    create(:credit_transaction, user: user, amount: 1000)
    create(:session, :jeu_libre, title: "Séance maintenue", start_at: start_at, end_at: start_at + 2.hours)
    create(:session, :jeu_libre, title: "Séance pluvieuse", start_at: start_at + 3.hours, end_at: start_at + 5.hours,
                     cancelled_at: Time.current, cancellation_reason: "meteo")
  end

  %w[calendar grid].each do |view|
    it "n'affiche pas les séances annulées dans la vue #{view}" do
      get sessions_path(view: view, date: start_at.to_date.iso8601)

      expect(response.body).to include("Séance maintenue")
      expect(response.body).not_to include("Séance pluvieuse")
    end
  end
end
