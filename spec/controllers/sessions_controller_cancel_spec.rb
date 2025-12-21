# frozen_string_literal: true

require 'rails_helper'

# Test unitaire de l'action cancel du SessionsController
RSpec.describe SessionsController, type: :controller do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:admin) { create(:user, :admin, activated_at: Time.current) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level, activated_at: Time.current) }
  let(:session_record) do
    create(:session,
           session_type: 'entrainement',
           terrain: 'Terrain 1',
           user: coach,
           levels: [ level ],
           start_at: 2.days.from_now,
           end_at: 2.days.from_now + 90.minutes)
  end

  before do
    # Donner des crédits au joueur
    create(:credit_transaction, user: player, amount: 1000)
  end

  describe 'POST #cancel' do
    context 'when admin tries to cancel' do
      it 'successfully cancels the session' do
        # Utiliser Warden directement au lieu de sign_in
        allow(controller).to receive(:current_user).and_return(admin)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)

        registration = create(:registration, user: player, session: session_record, status: :confirmed)
        initial_balance = player.reload.balance.amount

        expect {
          post :cancel, params: { id: session_record.id }
        }.to change { Session.exists?(session_record.id) }.from(true).to(false)

        expect(response).to redirect_to(sessions_path)
        expect(flash[:notice]).to include('annulée')
        expect(player.reload.balance.amount).to eq(initial_balance + session_record.price)
      end
    end

    context 'when coach tries to cancel their own session' do
      it 'cancels the session successfully' do
        allow(controller).to receive(:current_user).and_return(coach)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)

        expect {
          post :cancel, params: { id: session_record.id }
        }.to change { Session.exists?(session_record.id) }.from(true).to(false)

        expect(response).to redirect_to(sessions_path)
        expect(flash[:notice]).to include('annulée')
      end
    end

    context 'when non-owner coach tries to cancel' do
      let(:other_coach) { create(:user, :coach, activated_at: Time.current) }

      it 'denies access' do
        allow(controller).to receive(:current_user).and_return(other_coach)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)

        expect {
          post :cancel, params: { id: session_record.id }
        }.to raise_error(CanCan::AccessDenied)

        expect(Session.exists?(session_record.id)).to be true
      end
    end

    context 'when regular user tries to cancel' do
      let(:regular_user) { create(:user, activated_at: Time.current) }

      it 'denies access' do
        allow(controller).to receive(:current_user).and_return(regular_user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)

        expect {
          post :cancel, params: { id: session_record.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
