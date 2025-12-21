# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Users update", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  it 'updates user without requiring password when left blank' do
    login_as admin, scope: :user
    patch admin_user_path(user), params: { user: { first_name: 'Jane', password: '', password_confirmation: '' } }
    expect(response).to redirect_to(admin_user_path(user))
    expect(user.reload.first_name).to eq('Jane')
  end

  it 'adjusts credits via manual_adjustment' do
    login_as admin, scope: :user
    post adjust_credits_admin_user_path(user), params: { adjustment: { amount: 500 } }
    expect(response).to redirect_to(admin_user_path(user))
    expect(user.reload.balance.amount).to eq(500)
  end
end
