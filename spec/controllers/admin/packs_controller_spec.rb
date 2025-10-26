require 'rails_helper'

RSpec.describe Admin::PacksController, type: :controller do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:stage) { create(:stage) }

  describe 'authentication and authorization' do
    context 'when not signed in' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in as non-admin' do
      before { sign_in regular_user }

      it 'redirects to root with alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Accès interdit")
      end
    end
  end

  describe 'when signed in as admin' do
    before { sign_in admin_user }

    describe 'GET #index' do
      let!(:pack1) { create(:pack, position: 2) }
      let!(:pack2) { create(:pack, position: 1) }

      it 'assigns packs ordered by position' do
        get :index
        expect(assigns(:packs)).to eq([pack2, pack1])
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    describe 'GET #new' do
      it 'assigns a new pack with default values' do
        get :new
        expect(assigns(:pack)).to be_a_new(Pack)
        expect(assigns(:pack).active).to be true
        expect(assigns(:pack).pack_type).to eq('credits')
      end

      it 'assigns stages' do
        get :new
        expect(assigns(:stages)).to eq(Stage.ordered_for_players)
      end

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    describe 'POST #create' do
      context 'with valid parameters' do
        let(:valid_params) do
          {
            pack: {
              name: 'Test Pack',
              description: 'Test Description',
              pack_type: 'credits',
              amount_cents: 1000,
              credits: 1000,
              active: true,
              position: 1
            }
          }
        end

        it 'creates a new pack' do
          expect {
            post :create, params: valid_params
          }.to change(Pack, :count).by(1)
        end

        it 'redirects to index with notice' do
          post :create, params: valid_params
          expect(response).to redirect_to(admin_packs_path)
          expect(flash[:notice]).to eq("Pack créé avec succès")
        end
      end

      context 'with stage pack' do
        let(:stage_params) do
          {
            pack: {
              name: 'Stage Pack',
              description: 'Stage Description',
              pack_type: 'stage',
              amount_cents: 5000,
              stage_id: stage.id,
              active: true,
              position: 1
            }
          }
        end

        it 'creates a stage pack' do
          expect {
            post :create, params: stage_params
          }.to change(Pack, :count).by(1)
          
          pack = Pack.last
          expect(pack.pack_type).to eq('stage')
          expect(pack.stage).to eq(stage)
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            pack: {
              name: '',
              pack_type: 'credits',
              amount_cents: 1000
            }
          }
        end

        it 'does not create a pack' do
          expect {
            post :create, params: invalid_params
          }.not_to change(Pack, :count)
        end

        it 'renders new template' do
          post :create, params: invalid_params
          expect(response).to render_template(:new)
        end
      end
    end

    describe 'GET #edit' do
      let(:pack) { create(:pack) }

      it 'assigns the requested pack' do
        get :edit, params: { id: pack.id }
        expect(assigns(:pack)).to eq(pack)
      end

      it 'assigns stages' do
        get :edit, params: { id: pack.id }
        expect(assigns(:stages)).to eq(Stage.ordered_for_players)
      end

      it 'renders the edit template' do
        get :edit, params: { id: pack.id }
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH #update' do
      let(:pack) { create(:pack, name: 'Old Name') }

      context 'with valid parameters' do
        let(:valid_params) do
          {
            id: pack.id,
            pack: {
              name: 'New Name',
              description: 'New Description'
            }
          }
        end

        it 'updates the pack' do
          patch :update, params: valid_params
          pack.reload
          expect(pack.name).to eq('New Name')
          expect(pack.description).to eq('New Description')
        end

        it 'redirects to index with notice' do
          patch :update, params: valid_params
          expect(response).to redirect_to(admin_packs_path)
          expect(flash[:notice]).to eq("Pack mis à jour avec succès")
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            id: pack.id,
            pack: {
              name: ''
            }
          }
        end

        it 'does not update the pack' do
          patch :update, params: invalid_params
          pack.reload
          expect(pack.name).to eq('Old Name')
        end

        it 'renders edit template' do
          patch :update, params: invalid_params
          expect(response).to render_template(:edit)
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:pack) { create(:pack) }

      it 'deletes the pack' do
        expect {
          delete :destroy, params: { id: pack.id }
        }.to change(Pack, :count).by(-1)
      end

      it 'redirects to index with notice' do
        delete :destroy, params: { id: pack.id }
        expect(response).to redirect_to(admin_packs_path)
        expect(flash[:notice]).to eq("Pack supprimé")
      end
    end
  end
end
