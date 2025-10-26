require 'rails_helper'

RSpec.describe PacksController, type: :controller do
  let(:user) { create(:user) }
  let(:credits_pack) { create(:pack, :credits, active: true) }
  let(:licence_pack) { create(:pack, :licence, active: true) }
  let(:stage) { create(:stage) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns credits packs' do
      get :index
      expect(assigns(:credits_packs)).to include(credits_pack)
    end

    it 'assigns licence packs' do
      get :index
      expect(assigns(:licence_packs)).to include(licence_pack)
    end

    it 'assigns stages' do
      get :index
      expect(assigns(:stages)).to include(stage)
    end

    it 'assigns current balance' do
      get :index
      expect(assigns(:current_balance)).to eq(0)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'POST #buy' do
    context 'with valid pack' do
      it 'creates a credit purchase' do
        expect {
          post :buy, params: { id: credits_pack.id }
        }.to change(CreditPurchase, :count).by(1)
      end

      it 'sets the correct attributes on credit purchase' do
        post :buy, params: { id: credits_pack.id }
        credit_purchase = CreditPurchase.last
        expect(credit_purchase.user).to eq(user)
        expect(credit_purchase.pack).to eq(credits_pack)
        expect(credit_purchase.amount_cents).to eq(credits_pack.amount_cents)
        expect(credit_purchase.credits).to eq(credits_pack.credits)
        expect(credit_purchase.status).to eq('pending')
      end

      it 'renders payment HTML' do
        post :buy, params: { id: credits_pack.id }
        expect(response.content_type).to include('text/html')
      end
    end

    context 'with inactive pack' do
      let(:inactive_pack) { create(:pack, :credits, active: false) }

      it 'redirects with alert' do
        post :buy, params: { id: inactive_pack.id }
        expect(response).to redirect_to(packs_path)
        expect(flash[:alert]).to eq("Ce pack n'est plus disponible")
      end
    end

    context 'with non-existent pack' do
      it 'raises error' do
        expect {
          post :buy, params: { id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
