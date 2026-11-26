# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fusion de séances", type: :request do
  let(:slot) { 3.days.from_now.change(hour: 18) }
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let!(:kept) { create(:session, start_at: slot, end_at: slot + 90.minutes, max_players: 4) }
  let!(:absorbed) { create(:session, :terrain_2, user: coach, start_at: slot, end_at: slot + 90.minutes, max_players: 4) }

  def merge_params(**overrides)
    { absorbed_session_id: absorbed.id, coach_id: coach.id, max_players: 8 }.merge(overrides)
  end

  context "en admin" do
    before { sign_in create(:user, :admin) }

    it "propose les entraînements du même créneau sur la fiche" do
      get session_path(kept)

      expect(response.body).to include("Fusionner", "absorbed_session_id")
      expect(response.body).to include(%(value="#{absorbed.id}"))
    end

    it "fusionne et redirige vers la séance conservée" do
      post merge_session_path(kept), params: merge_params

      expect(response).to redirect_to(session_path(kept))
      expect(absorbed.reload).to have_attributes(cancelled?: true, cancellation_reason: "fusionnee")
      expect(kept.reload).to have_attributes(user: coach, max_players: 8)
    end

    it "affiche le refus sans rien modifier" do
      absorbed.update_column(:price, kept.price + 1)

      post merge_session_path(kept), params: merge_params

      expect(response).to redirect_to(session_path(kept))
      expect(flash[:alert]).to include("prix")
      expect(absorbed.reload).not_to be_cancelled
    end
  end

  it "est refusée à un coach" do
    sign_in coach

    expect { post merge_session_path(kept), params: merge_params }.to raise_error(CanCan::AccessDenied)
    expect(absorbed.reload).not_to be_cancelled
  end
end
