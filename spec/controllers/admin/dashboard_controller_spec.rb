# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :controller do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user) }
  let(:coach) { create(:user, coach: true, salary_per_training_cents: 5000) }

  before do
    # Give coach enough credits for private coaching
    coach.balance.update!(amount: 2000)
    warden = double('warden')
    allow(warden).to receive(:authenticate!).with(any_args).and_return(admin_user)
    allow(warden).to receive(:authenticate).with(any_args).and_return(admin_user)
    allow(warden).to receive(:authenticated?).with(any_args).and_return(true)
    allow(warden).to receive(:user).with(any_args).and_return(admin_user)
    request.env['warden'] = warden
  end

  describe 'GET #index' do
    context 'when user is admin' do
      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'assigns presenter instance variable' do
        get :index
        expect(assigns(:presenter)).to be_a(Admin::DashboardPresenter)
      end

      it 'assigns upcoming trainings' do
        week_start = Time.zone.now.beginning_of_week
        training = create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach)
        
        get :index
        expect(assigns(:upcoming_trainings)).to include(training)
      end

      it 'assigns upcoming free plays' do
        free_play = create(:session, session_type: 'jeu_libre', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach)
        
        get :index
        expect(assigns(:upcoming_free_plays)).to include(free_play)
      end

      it 'assigns upcoming private coachings' do
        private_coaching = create(:session, session_type: 'coaching_prive', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach)
        
        get :index
        expect(assigns(:upcoming_private_coachings)).to include(private_coaching)
      end

      it 'assigns current month revenue' do
        month_start = Time.zone.now.beginning_of_month
        create(:credit_transaction, user: regular_user, transaction_type: 'training_payment', amount: -350, created_at: month_start + 1.day)
        
        get :index
        expect(assigns(:current_month_revenue)).to eq(350)
      end

      it 'assigns coach salary data' do
        week_start = Time.zone.now.beginning_of_week
        create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach)
        
        get :index
        expect(assigns(:coach_salary_week)).to be_a(Numeric)
        expect(assigns(:coach_salary_month)).to be_a(Numeric)
        expect(assigns(:coach_salary_year)).to be_a(Numeric)
      end

      it 'assigns coach breakdown' do
        week_start = Time.zone.now.beginning_of_week
        create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach)
        
        get :index
        expect(assigns(:coach_breakdown)).to be_an(Array)
      end

      it 'assigns late cancellations' do
        training = create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach)
        late_cancellation = create(:late_cancellation, session: training, user: regular_user)
        
        get :index
        expect(assigns(:late_cancellations)).to include(late_cancellation)
      end

      it 'assigns late cancellation counts' do
        training = create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach)
        create(:late_cancellation, session: training, user: regular_user)
        
        get :index
        expect(assigns(:late_cancellation_counts)).to be_a(Hash)
        expect(assigns(:late_cancellation_counts)[regular_user.id]).to eq(1)
      end

      it 'assigns charges and revenue data' do
        week_start = Time.zone.now.beginning_of_week
        training = create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach)
        create(:credit_transaction, user: regular_user, transaction_type: 'training_payment', amount: -350, created_at: week_start + 1.day)
        create(:credit_transaction, user: regular_user, transaction_type: 'refund', amount: 200, created_at: week_start + 2.days)
        
        get :index
        
        expect(assigns(:weekly_charges)).to be_a(Numeric)
        expect(assigns(:monthly_charges)).to be_a(Numeric)
        expect(assigns(:weekly_revenue)).to be_a(Numeric)
        expect(assigns(:monthly_revenue)).to be_a(Numeric)
        expect(assigns(:weekly_net_profit)).to be_a(Numeric)
        expect(assigns(:monthly_net_profit)).to be_a(Numeric)
        
        expect(assigns(:weekly_charges_breakdown)).to be_a(Hash)
        expect(assigns(:monthly_charges_breakdown)).to be_a(Hash)
        expect(assigns(:weekly_revenue_breakdown)).to be_a(Numeric)
        expect(assigns(:monthly_revenue_breakdown)).to be_a(Numeric)
      end
    end

    context 'when user is not admin' do
      before do
        warden = double('warden')
        allow(warden).to receive(:authenticate!).with(any_args).and_return(regular_user)
        allow(warden).to receive(:authenticate).with(any_args).and_return(regular_user)
        allow(warden).to receive(:authenticated?).with(any_args).and_return(true)
        allow(warden).to receive(:user).with(any_args).and_return(regular_user)
        request.env['warden'] = warden
      end

      it 'redirects to root path with alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Accès non autorisé")
      end
    end

    context 'when user is not authenticated' do
      before do
        warden = double('warden')
        allow(warden).to receive(:authenticate!).with(any_args).and_return(nil)
        allow(warden).to receive(:authenticate).with(any_args).and_return(nil)
        allow(warden).to receive(:authenticated?).with(any_args).and_return(false)
        allow(warden).to receive(:user).with(any_args).and_return(nil)
        request.env['warden'] = warden
      end

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Accès non autorisé")
      end
    end
  end
end
