# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, 'Non-activated users' do
  let(:non_activated_user) { create(:user, activated_at: nil) }
  let(:activated_user) { create(:user, activated_at: Time.current) }

  describe '#active_for_authentication?' do
    it 'allows login for non-activated users' do
      expect(non_activated_user.active_for_authentication?).to be true
    end

    it 'allows login for activated users' do
      expect(activated_user.active_for_authentication?).to be true
    end

    context 'with disabled account' do
      let(:disabled_user) { create(:user, disabled_at: Time.current) }

      it 'prevents login for disabled users' do
        expect(disabled_user.active_for_authentication?).to be false
      end
    end
  end

  describe '#activated?' do
    it 'returns false for non-activated users' do
      expect(non_activated_user.activated?).to be false
    end

    it 'returns true for activated users' do
      expect(activated_user.activated?).to be true
    end
  end

  describe 'scopes' do
    before do
      non_activated_user
      activated_user
    end

    it 'finds non-activated users' do
      expect(User.not_activated).to include(non_activated_user)
      expect(User.not_activated).not_to include(activated_user)
    end

    it 'finds activated users' do
      expect(User.activated).to include(activated_user)
      expect(User.activated).not_to include(non_activated_user)
    end
  end
end

